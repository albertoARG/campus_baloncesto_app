-- Ejecutar en el SQL Editor de Supabase para soportar la funcionalidad de nivel
ALTER TABLE users ADD COLUMN IF NOT EXISTS nivel INT DEFAULT 3;

-- Comentario explicativo de la columna para la documentación de Supabase
COMMENT ON COLUMN users.nivel IS 'Nivel deportivo del jugador (1: Principiante, 2: Intermedio Bajo, 3: Intermedio Alto, 4: Avanzado, 5: Élite)';
