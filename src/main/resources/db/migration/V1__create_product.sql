-- FEAT-0001: tabela de produtos (PRD-001, seções 4 e 7).
-- As restrições espelham as regras de domínio para que o banco preserve a integridade mesmo
-- fora da aplicação. A unicidade do SKU normalizado é garantida por product_sku_uk.
CREATE TABLE product (
    id          UUID           NOT NULL,
    sku         VARCHAR(32)    NOT NULL,
    name        VARCHAR(120)   NOT NULL,
    description VARCHAR(500),
    price       NUMERIC(10, 2) NOT NULL,
    created_at  TIMESTAMPTZ    NOT NULL,
    updated_at  TIMESTAMPTZ    NOT NULL,
    CONSTRAINT product_pk PRIMARY KEY (id),
    CONSTRAINT product_sku_uk UNIQUE (sku),
    CONSTRAINT product_sku_format_ck CHECK (sku ~ '^[A-Z0-9][A-Z0-9_-]{2,31}$'),
    CONSTRAINT product_name_ck CHECK (char_length(name) BETWEEN 3 AND 120 AND name = btrim(name)),
    CONSTRAINT product_description_ck CHECK (
        description IS NULL OR (char_length(description) BETWEEN 1 AND 500 AND description = btrim(description))),
    CONSTRAINT product_price_ck CHECK (price > 0),
    CONSTRAINT product_timestamps_ck CHECK (updated_at >= created_at)
);
