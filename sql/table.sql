-- create table based on example schema
CREATE TABLE IF NOT EXISTS public.sales_target
(
    id     SERIAL PRIMARY KEY,
    sale_value INTEGER,
    biography TEXT,
	created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- create trigger to auto update "updated_at"
CREATE OR REPLACE FUNCTION update_modified_column()   
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;   
END;
$$ language 'plpgsql';

CREATE TRIGGER update_sales_target BEFORE UPDATE ON public.sales_target FOR EACH ROW EXECUTE PROCEDURE  update_modified_column();
