-- Anketler tablosu
CREATE TABLE surveys (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  soru TEXT NOT NULL,
  secenekler JSONB NOT NULL,
  oylar INTEGER[] NOT NULL,
  kilitlendi BOOLEAN DEFAULT FALSE,
  ikon TEXT,
  renk TEXT,
  min_yas INTEGER,
  il_filtresi BOOLEAN DEFAULT FALSE,
  belirli_il TEXT,
  okul_filtresi BOOLEAN DEFAULT FALSE,
  belirli_okul TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

-- Oylar tablosu
CREATE TABLE votes (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  survey_id UUID REFERENCES surveys(id) ON DELETE CASCADE,
  user_id TEXT NOT NULL,
  option_index INTEGER NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

-- Anket oylarini artirmak icin fonksiyon
CREATE OR REPLACE FUNCTION increment_survey_vote(survey_id UUID, option_index INTEGER)
RETURNS VOID AS $$
DECLARE
  current_votes INTEGER[];
BEGIN
  -- Mevcut oy dizisini al
  SELECT oylar INTO current_votes FROM surveys WHERE id = survey_id;
  
  -- Eger dizi yeterince uzun degilse, genislet
  WHILE array_length(current_votes, 1) <= option_index LOOP
    current_votes = array_append(current_votes, 0);
  END LOOP;
  
  -- Secilen secenegin oy sayisini artir
  current_votes[option_index + 1] = current_votes[option_index + 1] + 1;
  
  -- Guncellenmis oy dizisini kaydet
  UPDATE surveys SET oylar = current_votes WHERE id = survey_id;
END;
$$ LANGUAGE plpgsql;

-- Guncelleme zamani icin trigger
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = timezone('utc'::text, now());
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_surveys_updated_at
  BEFORE UPDATE ON surveys
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column(); 