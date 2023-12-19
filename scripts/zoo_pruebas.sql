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

