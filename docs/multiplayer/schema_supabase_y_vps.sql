-- ============================================================================
-- ESQUEMA SQL CANÓNICO: MULTIJUGADOR ONLINE, MONEDAS Y APUESTAS (GEM V4.0)
-- Compatible al 100% con Supabase (BaaS) y PostgreSQL Autónomo en VPS (Opción A).
-- ============================================================================

-- 1. EXTENSIONES Y SEGURIDAD
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. TABLA DE PERFILES DE JUGADORES Y BILLETERA
CREATE TABLE IF NOT EXISTS profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    auth_user_id TEXT UNIQUE, -- ID del proveedor Auth (Supabase Auth o VPS JWT)
    username VARCHAR(32) NOT NULL,
    avatar_url TEXT DEFAULT '',
    coins BIGINT NOT NULL DEFAULT 1000 CHECK (coins >= 0),
    elo_rating INT NOT NULL DEFAULT 1200 CHECK (elo_rating >= 100),
    matches_played INT NOT NULL DEFAULT 0,
    matches_won INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_profiles_coins ON profiles(coins);
CREATE INDEX IF NOT EXISTS idx_profiles_elo ON profiles(elo_rating);

-- 3. LIBRO MAYOR DE MONEDAS (LEDGER INMUTABLE - CERO CONDICIONES DE CARRERA)
CREATE TABLE IF NOT EXISTS coin_transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    profile_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    amount BIGINT NOT NULL, -- Positivo (ingreso) o Negativo (débito/apuesta)
    balance_after BIGINT NOT NULL CHECK (balance_after >= 0),
    transaction_type VARCHAR(32) NOT NULL CHECK (
        transaction_type IN ('signup_bonus', 'bet_escrow', 'prize_payout', 'bet_refund', 'reward_ad', 'iap_purchase')
    ),
    match_id UUID,
    description TEXT DEFAULT '',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_coin_tx_profile ON coin_transactions(profile_id);
CREATE INDEX IF NOT EXISTS idx_coin_tx_created ON coin_transactions(created_at);

-- 4. TABLA DE SALAS DE PARTIDAS ONLINE (MATCHES)
CREATE TABLE IF NOT EXISTS online_matches (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    room_code VARCHAR(16) UNIQUE NOT NULL,
    ruleset_id VARCHAR(32) NOT NULL DEFAULT 'spanish', -- spanish, international, etc.
    bet_amount BIGINT NOT NULL CHECK (bet_amount >= 0), -- ej. 50
    prize_amount BIGINT NOT NULL CHECK (prize_amount >= 0), -- ej. 90
    white_player_id UUID REFERENCES profiles(id),
    black_player_id UUID REFERENCES profiles(id),
    turn_color VARCHAR(1) NOT NULL DEFAULT 'w' CHECK (turn_color IN ('w', 'b')),
    status VARCHAR(20) NOT NULL DEFAULT 'waiting' CHECK (
        status IN ('waiting', 'active', 'completed', 'cancelled')
    ),
    winner_id UUID REFERENCES profiles(id),
    end_reason VARCHAR(32), -- mate, timeout, resign, draw, disconnect
    board_fen TEXT, -- Estado FEN o serializado de la partida
    move_count INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_online_matches_status_bet ON online_matches(status, bet_amount);

-- 5. PROCEDIMIENTOS ALMACENADOS ATÓMICOS CON BLOQUEO ACID (ROW-LEVEL LOCKING)
-- Garantiza que NADIE pueda duplicar monedas ni apostar más de lo que tiene.

-- A. Unirse o crear una partida con apuesta de monedas en depósito (Escrow)
CREATE OR REPLACE FUNCTION join_or_create_match_escrow(
    p_player_id UUID,
    p_bet_amount BIGINT,
    p_prize_amount BIGINT,
    p_ruleset VARCHAR(32)
)
RETURNS JSONB
LANGUAGE plpgsql
AS $$
DECLARE
    v_player_coins BIGINT;
    v_new_balance BIGINT;
    v_open_match_id UUID;
    v_result JSONB;
BEGIN
    -- 1. Bloquear la fila del jugador para evitar apuestas concurrentes (FOR UPDATE)
    SELECT coins INTO v_player_coins
    FROM profiles
    WHERE id = p_player_id
    FOR UPDATE;

    IF v_player_coins IS NULL THEN
        RAISE EXCEPTION 'Jugador no encontrado.';
    END IF;

    IF v_player_coins < p_bet_amount THEN
        RAISE EXCEPTION 'Saldo insuficiente (% monedas) para apuesta de %.', v_player_coins, p_bet_amount;
    END IF;

    -- 2. Descontar apuesta y registrar en el libro mayor inmutable
    v_new_balance := v_player_coins - p_bet_amount;
    UPDATE profiles SET coins = v_new_balance, updated_at = NOW() WHERE id = p_player_id;

    -- 3. Buscar sala en espera con la misma apuesta y reglas
    SELECT id INTO v_open_match_id
    FROM online_matches
    WHERE status = 'waiting'
      AND bet_amount = p_bet_amount
      AND ruleset_id = p_ruleset
      AND white_player_id <> p_player_id
    ORDER BY created_at ASC
    LIMIT 1
    FOR UPDATE SKIP LOCKED;

    IF v_open_match_id IS NOT NULL THEN
        -- Se encontró rival: Entra como Negras y arranca la partida
        UPDATE online_matches
        SET black_player_id = p_player_id,
            status = 'active',
            updated_at = NOW()
        WHERE id = v_open_match_id;

        INSERT INTO coin_transactions (profile_id, amount, balance_after, transaction_type, match_id, description)
        VALUES (p_player_id, -p_bet_amount, v_new_balance, 'bet_escrow', v_open_match_id, 'Apuesta partida match ' || v_open_match_id);

        v_result := jsonb_build_object(
            'action', 'matched',
            'match_id', v_open_match_id,
            'role', 'black',
            'coins_left', v_new_balance
        );
    ELSE
        -- No hay rival esperando: Crear nueva sala y esperar
        v_open_match_id := uuid_generate_v4();
        INSERT INTO online_matches (id, room_code, ruleset_id, bet_amount, prize_amount, white_player_id, status)
        VALUES (v_open_match_id, UPPER(SUBSTRING(v_open_match_id::TEXT FROM 1 FOR 6)), p_ruleset, p_bet_amount, p_prize_amount, p_player_id, 'waiting');

        INSERT INTO coin_transactions (profile_id, amount, balance_after, transaction_type, match_id, description)
        VALUES (p_player_id, -p_bet_amount, v_new_balance, 'bet_escrow', v_open_match_id, 'Apuesta sala creada ' || v_open_match_id);

        v_result := jsonb_build_object(
            'action', 'waiting',
            'match_id', v_open_match_id,
            'role', 'white',
            'coins_left', v_new_balance
        );
    END IF;

    RETURN v_result;
END;
$$;

-- B. Finalizar partida y entregar el premio al ganador (Escrow Release)
CREATE OR REPLACE FUNCTION finalize_match_escrow(
    p_match_id UUID,
    p_winner_id UUID,
    p_end_reason VARCHAR(32)
)
RETURNS JSONB
LANGUAGE plpgsql
AS $$
DECLARE
    v_match online_matches%ROWTYPE;
    v_winner_coins BIGINT;
    v_new_balance BIGINT;
BEGIN
    SELECT * INTO v_match
    FROM online_matches
    WHERE id = p_match_id
    FOR UPDATE;

    IF v_match.id IS NULL THEN
        RAISE EXCEPTION 'Partida no encontrada.';
    END IF;

    IF v_match.status = 'completed' THEN
        RETURN jsonb_build_object('status', 'already_completed');
    END IF;

    -- Acreditar premio al ganador
    SELECT coins INTO v_winner_coins FROM profiles WHERE id = p_winner_id FOR UPDATE;
    v_new_balance := v_winner_coins + v_match.prize_amount;

    UPDATE profiles
    SET coins = v_new_balance,
        matches_played = matches_played + 1,
        matches_won = matches_won + 1,
        elo_rating = elo_rating + 16,
        updated_at = NOW()
    WHERE id = p_winner_id;

    -- Actualizar perdedor
    UPDATE profiles
    SET matches_played = matches_played + 1,
        elo_rating = GREATEST(100, elo_rating - 14),
        updated_at = NOW()
    WHERE id IN (v_match.white_player_id, v_match.black_player_id)
      AND id <> p_winner_id;

    -- Cerrar sala
    UPDATE online_matches
    SET status = 'completed',
        winner_id = p_winner_id,
        end_reason = p_end_reason,
        updated_at = NOW()
    WHERE id = p_match_id;

    -- Registrar transacción en libro mayor
    INSERT INTO coin_transactions (profile_id, amount, balance_after, transaction_type, match_id, description)
    VALUES (p_winner_id, v_match.prize_amount, v_new_balance, 'prize_payout', p_match_id, 'Premio victoria en partida');

    RETURN jsonb_build_object(
        'status', 'payout_completed',
        'winner_id', p_winner_id,
        'prize', v_match.prize_amount,
        'new_balance', v_new_balance
    );
END;
$$;

-- C. Cancelar o reembolsar sala si no se encontró rival
CREATE OR REPLACE FUNCTION cancel_and_refund_match(
    p_match_id UUID,
    p_player_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
AS $$
DECLARE
    v_bet BIGINT;
    v_new_balance BIGINT;
BEGIN
    SELECT bet_amount INTO v_bet
    FROM online_matches
    WHERE id = p_match_id
      AND white_player_id = p_player_id
      AND status = 'waiting'
    FOR UPDATE;

    IF v_bet IS NULL THEN
        RAISE EXCEPTION 'No se puede reembolsar una sala activa o inexistente.';
    END IF;

    UPDATE online_matches SET status = 'cancelled', updated_at = NOW() WHERE id = p_match_id;

    UPDATE profiles
    SET coins = coins + v_bet, updated_at = NOW()
    WHERE id = p_player_id
    RETURNING coins INTO v_new_balance;

    INSERT INTO coin_transactions (profile_id, amount, balance_after, transaction_type, match_id, description)
    VALUES (p_player_id, v_bet, v_new_balance, 'bet_refund', p_match_id, 'Reembolso por sala cancelada');

    RETURN jsonb_build_object('status', 'refunded', 'coins', v_new_balance);
END;
$$;
