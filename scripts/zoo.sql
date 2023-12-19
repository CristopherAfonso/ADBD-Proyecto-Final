/*
    Modo de uso:
      1. sudo su postgres
      2. psql
      \i zoo.sql
*/

/* Borrar todas las tablas en el esquema 'public' */
DROP SCHEMA public CASCADE;
CREATE SCHEMA public;

-----------------------------TABLES-----------------------------
-- Ahora creamos las 19 tablas que necesita esta base de datos

-- Creamos la tabla 1 'zoo'
CREATE TABLE zoo (
    codigo_zoo SERIAL,
    nombre_zoo VARCHAR NOT NULL,
    latitud DOUBLE PRECISION CHECK (latitud BETWEEN -90 AND 90),
    longitud DOUBLE PRECISION CHECK (longitud BETWEEN -180 AND 180),
    numero_animales INTEGER NOT NULL DEFAULT 0 CHECK (numero_animales >= 0), -- TODO TRIGGER (El número de animales es la suma del número de animales de todas las zonas de ese zoo (tabla animal-área))
    PRIMARY KEY (codigo_zoo)
);

-- Creamos la tabla 2 'personal'
CREATE TABLE personal (
    DNI VARCHAR,
    numero_seguridad_social VARCHAR NOT NULL,
    nombre VARCHAR NOT NULL,
    direccion VARCHAR NOT NULL,
    sueldo DECIMAL NOT NULL CHECK (sueldo >= 0),
    codigo_zoo INTEGER NOT NULL,
    PRIMARY KEY (DNI),
    FOREIGN KEY (codigo_zoo) REFERENCES zoo(codigo_zoo) ON DELETE CASCADE
);

-- Creamos la tabla 3 'telefono_personal'
CREATE TABLE telefono_personal (
    DNI VARCHAR NOT NULL,
    telefono VARCHAR NOT NULL,
    PRIMARY KEY (DNI, telefono),
    FOREIGN KEY (DNI) REFERENCES personal(DNI) ON DELETE CASCADE
);

-- Creamos la tabla 4 'cuidador'
CREATE TABLE cuidador (
    DNI VARCHAR,
    codigo_area INTEGER NOT NULL,
    PRIMARY KEY (DNI),
    FOREIGN KEY (DNI) REFERENCES personal(DNI) ON DELETE CASCADE
);

-- Creamos la tabla 5 'mantenimiento'
CREATE TABLE mantenimiento (
    DNI VARCHAR,
    codigo_area INTEGER NOT NULL,
    PRIMARY KEY (DNI),
    FOREIGN KEY (DNI) REFERENCES personal(DNI) ON DELETE CASCADE
);

-- Creamos la tabla 6 'vigilante'
CREATE TABLE vigilante (
    DNI VARCHAR,
    codigo_area INTEGER NOT NULL,
    PRIMARY KEY (DNI),
    FOREIGN KEY (DNI) REFERENCES personal(DNI) ON DELETE CASCADE
);

-- Creamos la tabla 7 'vehiculo'
CREATE TABLE vehiculo (
    DNI VARCHAR NOT NULL,
    matricula VARCHAR,
    PRIMARY KEY (matricula),
    FOREIGN KEY (DNI) REFERENCES vigilante(DNI) ON DELETE CASCADE
);

-- Creamos la tabla 8 'veterinario'
CREATE TABLE veterinario (
    numero_seguridad_social VARCHAR,
    nombre VARCHAR NOT NULL,
    PRIMARY KEY (numero_seguridad_social)
);

-- Creamos la tabla 9 'veterinario_telefono'
CREATE TABLE veterinario_telefono (
    numero_seguridad_social VARCHAR NOT NULL,
    telefono VARCHAR NOT NULL,
    PRIMARY KEY (numero_seguridad_social, telefono),
    FOREIGN KEY (numero_seguridad_social) REFERENCES veterinario(numero_seguridad_social) ON DELETE CASCADE
);

-- Creamos la tabla 10 'entrada'
CREATE TABLE entrada (
    codigo_entrada SERIAL,
    codigo_zoo INTEGER NOT NULL,
    PRIMARY KEY (codigo_entrada),
    FOREIGN KEY (codigo_zoo) REFERENCES zoo(codigo_zoo) ON DELETE CASCADE
);

-- Creamos la tabla 11 'area'
CREATE TABLE area (
    codigo_zoo INTEGER NOT NULL,
    codigo_area SERIAL,
    nombre_area VARCHAR NOT NULL,
    tamano DOUBLE PRECISION CHECK (tamano > 0), -- Metros cuadrados
    capacidad INTEGER CHECK (capacidad >= 0), -- Número de animales (TODO TRIGGER) Comprobar si se puede insertar animal en zona llena (animal-area)
    PRIMARY KEY (codigo_area),
    FOREIGN KEY (codigo_zoo) REFERENCES zoo(codigo_zoo) ON DELETE CASCADE
);

-- Creamos la tabla 12 'animal'
CREATE TABLE animal (
    codigo_animal SERIAL,
    dieta VARCHAR NOT NULL,
    nombre_cientifico VARCHAR NOT NULL,
    nombre_comun VARCHAR NOT NULL,
    tipo VARCHAR NOT NULL,
    PRIMARY KEY (codigo_animal)
);

-- Creamos la tabla 13 'animal_animal'
CREATE TABLE animal_animal (
    codigo_animal_padre INTEGER NOT NULL,
    codigo_animal_hijo INTEGER NOT NULL,
    tipo VARCHAR NOT NULL,
    PRIMARY KEY (codigo_animal_padre, codigo_animal_hijo, tipo),
    FOREIGN KEY (codigo_animal_padre) REFERENCES animal(codigo_animal) ON DELETE CASCADE,
    FOREIGN KEY (codigo_animal_hijo) REFERENCES animal(codigo_animal) ON DELETE CASCADE 
);

-- Creamos la tabla 14 'gestor'
CREATE TABLE gestor (
    DNI VARCHAR,
    codigo_entrada INTEGER NOT NULL,
    PRIMARY KEY (DNI),
    FOREIGN KEY (DNI) REFERENCES personal(DNI) ON DELETE CASCADE,
    FOREIGN KEY (codigo_entrada) REFERENCES entrada(codigo_entrada) ON DELETE CASCADE
);

-- Creamos la tabla 15 'investigador'
CREATE TABLE investigador (
    DNI VARCHAR,
    PRIMARY KEY (DNI),
    FOREIGN KEY (DNI) REFERENCES personal(DNI) ON DELETE CASCADE
);

-- Creamos la tabla 16 'proyecto'
CREATE TABLE proyecto (
    codigo_proyecto SERIAL,
    presupuesto DECIMAL CHECK (presupuesto >= 0),
    fecha_final DATE NOT NULL,
    codigo_animal INTEGER NOT NULL,
    PRIMARY KEY (codigo_proyecto),
    FOREIGN KEY (codigo_animal) REFERENCES animal(codigo_animal) ON DELETE CASCADE
);

-- Creamos la tabla 17 'i_pro'
CREATE TABLE i_pro (
    DNI VARCHAR NOT NULL,
    codigo_proyecto INTEGER NOT NULL,
    PRIMARY KEY (DNI, codigo_proyecto),
    FOREIGN KEY (DNI) REFERENCES investigador(DNI) ON DELETE CASCADE,
    FOREIGN KEY (codigo_proyecto) REFERENCES proyecto(codigo_proyecto) ON DELETE CASCADE
);

-- Creamos la tabla 18 'ani_area_cuidador'
CREATE TABLE ani_area_cuidador (
    DNI VARCHAR NOT NULL,
    codigo_area INTEGER NOT NULL,
    codigo_animal INTEGER NOT NULL,
    numero_animales INTEGER NOT NULL DEFAULT 0 CHECK (numero_animales >= 0),
    PRIMARY KEY (DNI, codigo_area, codigo_animal),
    FOREIGN KEY (DNI) REFERENCES cuidador(DNI) ON DELETE CASCADE,
    FOREIGN KEY (codigo_area) REFERENCES area(codigo_area) ON DELETE CASCADE,
    FOREIGN KEY (codigo_animal) REFERENCES animal(codigo_animal) ON DELETE CASCADE
);

-- Creamos la tabla 19 'vet_ani'
CREATE TABLE vet_ani (
    numero_seguridad_social VARCHAR NOT NULL,
    codigo_animal INTEGER NOT NULL,
    fecha DATE DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (numero_seguridad_social, codigo_animal, fecha),
    FOREIGN KEY (numero_seguridad_social) REFERENCES veterinario(numero_seguridad_social) ON DELETE CASCADE,
    FOREIGN KEY (codigo_animal) REFERENCES area(codigo_area) ON DELETE CASCADE
);




-----------------------------TRIGGERS-----------------------------

-- Primera función usada por el primer disparador, coje el valor de la fila
-- actual de la tabla 'zoo' y le suma la cantidad de animales que hay en
-- la nueva fila a insertar
CREATE OR REPLACE FUNCTION actualizar_numero_animales_zoo()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE zoo
    SET numero_animales = numero_animales + NEW.numero_animales
    WHERE codigo_zoo = (
        SELECT codigo_zoo
        FROM area
        WHERE codigo_area = NEW.codigo_area
    );

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Primer trigger, después de insertar una fila en la tabla 'ani_area_cuidador'
-- cogemos la cantidad de animales que tiene y se la añadimos a su zoo
CREATE TRIGGER trigger_actualizar_numero_animales_zoo
AFTER INSERT ON ani_area_cuidador
FOR EACH ROW
EXECUTE FUNCTION actualizar_numero_animales_zoo();





-- Segunda función usada por el segundo disparador, antes de meter un nuevo
-- valor en la tabla, 'ani_area_cuidador' nos aseguramos de que no hay más
-- animales en ese área determinada que los que tiene permitido
CREATE OR REPLACE FUNCTION verificar_capacidad()
RETURNS TRIGGER AS $$
DECLARE
    capacidad_actual INTEGER;
    suma_animales INTEGER;
BEGIN
    -- Obtener la capacidad actual del área
    SELECT capacidad INTO capacidad_actual
    FROM area
    WHERE codigo_area = NEW.codigo_area;

    -- Obtener la suma actual de animales en el área
    SELECT COALESCE(SUM(numero_animales), 0) INTO suma_animales
    FROM ani_area_cuidador
    WHERE codigo_area = NEW.codigo_area;

    -- Verificar si la capacidad se supera con la nueva inserción
    IF suma_animales + NEW.numero_animales > capacidad_actual THEN
        RAISE EXCEPTION 'La capacidad del área se supera con la nueva inserción';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Segundo trigger, antes de insertar una fila en la tabla 'ani_area_cuidador'
-- comprobamos que no superamos la cantidad de animales permitida en ese área,
-- si efectivamente la superamos, nos lanza un mensaje de error y rechaza la 
-- inserción
CREATE TRIGGER trigger_verificar_capacidad
BEFORE INSERT ON ani_area_cuidador
FOR EACH ROW
EXECUTE FUNCTION verificar_capacidad();





-----------------------------INSERCTIONS-----------------------------
-- Inserciones para la tabla 1 'zoo'
INSERT INTO zoo (nombre_zoo, latitud, longitud) VALUES
('Zoo de la Montaña', 40.7128, -74.0060),
('Zoo del Bosque', 34.0522, -118.2437),
('Zoo del Desierto', 25.7617, -80.1918),
('Zoo Marino', 36.7783, -119.4179),
('Zoo Tropical', 28.6139, 77.2090);

-- Inserciones para la tabla 2 'personal'
INSERT INTO personal (DNI, numero_seguridad_social, nombre, direccion, sueldo, codigo_zoo) VALUES
('12345678A', 'NSS123', 'Juan Pérez', 'Calle Falsa 123', 2000.00, 1),
('23456789B', 'NSS456', 'Ana Gómez', 'Avenida de la Luz 45', 1800.00, 2),
('34567890C', 'NSS789', 'Luis Rodríguez', 'Plaza Mayor 5', 2200.00, 3),
('45678901D', 'NSS012', 'Carmen López', 'Calle Nueva 67', 2100.00, 4),
('56789012E', 'NSS034', 'Mario Vargas', 'Calle Vieja 89', 1900.00, 5);

-- Inserciones para la tabla 3 'telefono_personal'
INSERT INTO telefono_personal (DNI, telefono) VALUES
('12345678A', '600123456'),
('23456789B', '600234567'),
('34567890C', '600345678'),
('45678901D', '600456789'),
('56789012E', '600567890');

-- Inserciones para la tabla 4 'cuidador'
INSERT INTO cuidador (DNI, codigo_area) VALUES
('12345678A', 1),
('23456789B', 2),
('34567890C', 3),
('45678901D', 4),
('56789012E', 5);

-- Inserciones para la tabla 5 'mantenimiento'
INSERT INTO mantenimiento (DNI, codigo_area) VALUES
('12345678A', 2),
('23456789B', 3),
('34567890C', 4),
('45678901D', 5),
('56789012E', 1);

-- Inserciones para la tabla 6 'vigilante'
INSERT INTO vigilante (DNI, codigo_area) VALUES
('12345678A', 3),
('23456789B', 4),
('34567890C', 5),
('45678901D', 1),
('56789012E', 2);

-- Inserciones para la tabla 7 'vehiculo'
INSERT INTO vehiculo (DNI, matricula) VALUES
('12345678A', '1234ABC'),
('23456789B', '5678DEF'),
('34567890C', '9012GHI'),
('45678901D', '3456JKL'),
('56789012E', '7890MNO');

-- Inserciones para la tabla 8 'veterinario'
INSERT INTO veterinario (numero_seguridad_social, nombre) VALUES
('NSS101', 'Carlos Martín'),
('NSS102', 'Marta Díaz'),
('NSS103', 'Sofía Núñez'),
('NSS104', 'Alberto Fernández'),
('NSS105', 'Lucía Ramírez');

-- Inserciones para la tabla 9 'veterinario_telefono'
INSERT INTO veterinario_telefono (numero_seguridad_social, telefono) VALUES
('NSS101', '700123456'),
('NSS102', '700234567'),
('NSS103', '700345678'),
('NSS104', '700456789'),
('NSS105', '700567890');

-- Inserciones para la tabla 10 'entrada'
INSERT INTO entrada (codigo_zoo) VALUES
(1), (2), (3), (4), (5);

-- Inserciones para la tabla 11 'area'
INSERT INTO area (codigo_zoo, nombre_area, tamano, capacidad) VALUES
(1, 'Sabana Africana', 1000.00, 50),
(2, 'Bosque Tropical', 800.00, 40),
(3, 'Desierto', 500.00, 30),
(4, 'Zona Acuática', 1200.00, 60),
(5, 'Aviario', 700.00, 35);

-- Inserciones para la tabla 12 'animal'
INSERT INTO animal (dieta, nombre_cientifico, nombre_comun, tipo) VALUES
('Herbívoro', 'Panthera leo', 'León', 'Mamífero'),
('Carnívoro', 'Elephas maximus', 'Elefante', 'Mamífero'),
('Omnívoro', 'Ara macao', 'Guacamayo', 'Ave'),
('Herbívoro', 'Giraffa camelopardalis', 'Jirafa', 'Mamífero'),
('Carnívoro', 'Panthera onca', 'Jaguar', 'Mamífero');

-- Inserciones para la tabla 13 'animal_animal'
-- Asegúrate de que los códigos de animales existen
INSERT INTO animal_animal (codigo_animal_padre, codigo_animal_hijo, tipo) VALUES
(1, 2, 'cazador-presa'),
(2, 3, 'comensalismo'),
(3, 4, 'comensalismo'),
(4, 5, 'cazador-presa'),
(5, 1, 'competencia de presas');

-- Inserciones para la tabla 14 'gestor'
INSERT INTO gestor (DNI, codigo_entrada) VALUES
('12345678A', 1),
('23456789B', 2),
('34567890C', 3),
('45678901D', 4),
('56789012E', 5);

-- Inserciones para la tabla 15 'investigador'
INSERT INTO investigador (DNI) VALUES
('12345678A'),
('23456789B'),
('34567890C'),
('45678901D'),
('56789012E');

-- Inserciones para la tabla 16 'proyecto'
INSERT INTO proyecto (presupuesto, fecha_final, codigo_animal) VALUES
(10000.00, '2023-12-31', 1),
(15000.00, '2024-06-30', 2),
(20000.00, '2024-12-31', 3),
(25000.00, '2025-06-30', 4),
(30000.00, '2025-12-31', 5);

-- Inserciones para la tabla 17 'i_pro'
-- Asegúrate de que los DNI y códigos de proyecto existen
INSERT INTO i_pro (DNI, codigo_proyecto) VALUES
('12345678A', 1),
('23456789B', 2),
('34567890C', 3),
('45678901D', 4),
('56789012E', 5);

-- Inserciones para la tabla 18 'ani_area_cuidador'
-- Asegúrate de que los DNI, códigos de área y animales existen
INSERT INTO ani_area_cuidador (DNI, codigo_area, codigo_animal, numero_animales) VALUES
('12345678A', 1, 1, DEFAULT),
('23456789B', 2, 2, 1),
('34567890C', 3, 3, 3),
('45678901D', 4, 4, 5),
('56789012E', 5, 5, 7);

-- Inserciones para la tabla 19 'vet_ani'
-- Asegúrate de que los números de seguridad social y códigos de animales existen
INSERT INTO vet_ani (numero_seguridad_social, codigo_animal) VALUES
('NSS101', 1),
('NSS102', 2),
('NSS103', 3),
('NSS104', 4),
('NSS105', 5);

-----------------------------SHOW DATA-----------------------------
SELECT * FROM zoo;
SELECT * FROM personal;
SELECT * FROM telefono_personal;
SELECT * FROM cuidador;
SELECT * FROM mantenimiento;
SELECT * FROM vigilante;
SELECT * FROM vehiculo;
SELECT * FROM veterinario;
SELECT * FROM veterinario_telefono;
SELECT * FROM entrada;
SELECT * FROM area;
SELECT * FROM animal;
SELECT * FROM animal_animal;
SELECT * FROM gestor;
SELECT * FROM investigador;
SELECT * FROM proyecto;
SELECT * FROM i_pro;
SELECT * FROM ani_area_cuidador;
SELECT * FROM vet_ani;


-----------------------------PRUEBAS CHECK-----------------------------
-- Pruebas CHECK tabla 1 'zoo'
SELECT * FROM zoo;

INSERT INTO zoo (nombre_zoo, latitud, longitud, numero_animales) VALUES ('CHECK latitud -90', -90.0001, -74.0060, 0);
INSERT INTO zoo (nombre_zoo, latitud, longitud, numero_animales) VALUES ('CHECK latitud +90', 90.0001, -118.2437, 0);
INSERT INTO zoo (nombre_zoo, latitud, longitud, numero_animales) VALUES ('CHECK longitud -180', 25.7617, -180.0001, 0);
INSERT INTO zoo (nombre_zoo, latitud, longitud, numero_animales) VALUES ('CHECK longitud +180', 36.7783, 180.0001, 0);
INSERT INTO zoo (nombre_zoo, latitud, longitud, numero_animales) VALUES ('CHECK numero_animales < 0', 28.6139, 77.2090, -1);

SELECT * FROM zoo;


-- Pruebas CHECK tabla 2 'personal'
SELECT * FROM personal;

INSERT INTO personal (DNI, numero_seguridad_social, nombre, direccion, sueldo, codigo_zoo) VALUES
('12345678A', 'NSS123', 'CHECK sueldo >= 0', 'Calle Falsa 123', -0.01, 1);

SELECT * FROM personal;


-- Pruebas CHECK tabla 11 'area'
SELECT * FROM area;

INSERT INTO area (codigo_zoo, nombre_area, tamano, capacidad) VALUES (1, 'Sabana Africana', 0.00, 50);
INSERT INTO area (codigo_zoo, nombre_area, tamano, capacidad) VALUES (2, 'Bosque Tropical', -0.01, 40);
INSERT INTO area (codigo_zoo, nombre_area, tamano, capacidad) VALUES (3, 'Desierto', 500.00, -1);

SELECT * FROM area;


-- Pruebas CHECK tabla 16 'proyecto'
SELECT * FROM proyecto;

INSERT INTO proyecto (presupuesto, fecha_final, codigo_animal) VALUES (-0.01, '2023-12-31', 1);

SELECT * FROM proyecto;


-- Pruebas CHECK tabla 18 'ani_area_cuidador'
SELECT * FROM ani_area_cuidador;

INSERT INTO ani_area_cuidador (DNI, codigo_area, codigo_animal, numero_animales) VALUES ('12345678A', 1, 2, -1);

SELECT * FROM ani_area_cuidador;

