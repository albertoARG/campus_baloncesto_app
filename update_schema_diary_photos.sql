-- SQL Script para añadir galería de imágenes a las Crónicas (Diary)

-- 1. Actualizar tabla diary_posts con el campo de galería de imágenes
ALTER TABLE public.diary_posts 
ADD COLUMN IF NOT EXISTS image_urls TEXT[];
