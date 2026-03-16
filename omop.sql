CREATE DATABASE omop_cdm
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;
  create database omop1
    CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;


use omop1;
show tables
select  count(*) from concept
select DISTINCT vocabulary_id
from concept
SELECT COUNT(*) FROM CONCEPT_RELATIONSHIP;
SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE concept;
SET FOREIGN_KEY_CHECKS = 1;
SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE RELATIONSHIP;
SET FOREIGN_KEY_CHECKS = 1;
ALTER TABLE concept 
MODIFY concept_name VARCHAR(4000);
LOAD DATA INFILE
SHOW COLUMNS FROM concept;
CREATE TABLE vocabulary (
    vocabulary_id VARCHAR(20) PRIMARY KEY,
    vocabulary_name VARCHAR(255),
    vocabulary_version VARCHAR(50)
);

-- CONCEPT TABLE (MOST IMPORTANT)
CREATE TABLE concept (
    concept_id INT PRIMARY KEY,
    concept_name VARCHAR(255),
    domain_id VARCHAR(50),
    vocabulary_id VARCHAR(20),
    concept_class_id VARCHAR(50),
    standard_concept CHAR(1),
    concept_code VARCHAR(50),
    valid_start_date DATE,
    valid_end_date DATE
);
-- Insert vocabularies
INSERT INTO vocabulary VALUES
('SNOMED', 'Systematized Nomenclature of Medicine', 'v1'),
('LOINC', 'Logical Observation Identifiers Names and Codes', 'v1'),
('RxNorm', 'Drug Vocabulary', 'v1'),
('Gender', 'Gender Vocabulary', 'v1');
INSERT INTO concept VALUES
-- Gender
(8507, 'Male', 'Gender', 'Gender', 'Clinical', 'S', 'M', '2000-01-01', '2099-12-31'),
(8532, 'Female', 'Gender', 'Gender', 'Clinical', 'S', 'F', '2000-01-01', '2099-12-31'),
-- SNOMED (Conditions)
(201826, 'Type 2 diabetes mellitus', 'Condition', 'SNOMED', 'Clinical', 'S', 'T2DM', '2000-01-01', '2099-12-31'),
-- LOINC (Measurements)
(3004410, 'Hemoglobin measurement', 'Measurement', 'LOINC', 'Clinical', 'S', 'HB', '2000-01-01', '2099-12-31'),
-- RxNorm (Drugs)
(1503297, 'Metformin', 'Drug', 'RxNorm', 'Clinical', 'S', 'MET', '2000-01-01', '2099-12-31');
INSERT INTO person (
gender_concept_id,
year_of_birth,
race_concept_id,
ethnicity_concept_id
)
VALUES (8532, 2000, 0, 0);
INSERT INTO visit_occurrence (
person_id,
visit_concept_id,
visit_start_date,
visit_end_date,
visit_type_concept_id
)
VALUES (1, 0, '2024-01-01', '2024-01-01', 0);
INSERT INTO condition_occurrence (
person_id,
condition_concept_id,
condition_start_date,
condition_type_concept_id,
visit_occurrence_id
)
VALUES (1, 201826, '2024-01-01', 0, 1);
INSERT INTO measurement (
person_id,
measurement_concept_id,
measurement_date,
value_as_number
)
VALUES (1, 3004410, '2024-01-01', 13.5);
INSERT INTO drug_exposure (
person_id,
drug_concept_id,
drug_exposure_start_date,
drug_type_concept_id
)
VALUES (1, 1503297, '2024-01-01', 0);
SELECT 
    p.person_id,
    p.gender_concept_id,
    c.concept_name AS gender
FROM person p
JOIN concept c
ON p.gender_concept_id = c.concept_id;
SELECT 
    co.condition_occurrence_id,
    co.person_id,
    co.condition_concept_id,
    c.concept_name AS disease
FROM condition_occurrence co
JOIN concept c
ON co.condition_concept_id = c.concept_id;
SELECT 
    de.drug_exposure_id,
    de.person_id,
    de.drug_concept_id,
    c.concept_name AS drug_name
FROM drug_exposure de
JOIN concept c
ON de.drug_concept_id = c.concept_id;
	SELECT 
    m.measurement_id,
    m.person_id,
    m.measurement_concept_id,
    c.concept_name AS test_name,
    m.value_as_number
FROM measurement m
JOIN concept c
ON m.measurement_concept_id = c.concept_id;
SELECT 
    p.person_id,
    g.concept_name AS gender,
    cond.concept_name AS disease,
    drug.concept_name AS drug,
    meas.concept_name AS measurement,
    m.value_as_number
FROM person p

LEFT JOIN concept g
ON p.gender_concept_id = g.concept_id

LEFT JOIN condition_occurrence co
ON p.person_id = co.person_id

LEFT JOIN concept cond
ON co.condition_concept_id = cond.concept_id

LEFT JOIN drug_exposure de
ON p.person_id = de.person_id

LEFT JOIN concept drug
ON de.drug_concept_id = drug.concept_id

LEFT JOIN measurement m
ON p.person_id = m.person_id

LEFT JOIN concept meas
ON m.measurement_concept_id = meas.concept_id;

SELECT COUNT(*)
FROM person
WHERE person_id IS NULL;

SELECT COUNT(*)
FROM person
WHERE gender_concept_id IS NULL;

SELECT COUNT(*)
FROM person
WHERE gender_concept_id IS NULL;

SELECT v.person_id
FROM visit_occurrence v
LEFT JOIN person p
ON v.person_id = p.person_id
WHERE p.person_id IS NULL;

SELECT m.person_id
FROM measurement m
LEFT JOIN person p
ON m.person_id = p.person_id
WHERE p.person_id IS NULL;

SELECT COUNT(*) FROM person;
SELECT COUNT(*) FROM visit_occurrence;
SELECT COUNT(*) FROM condition_occurrence;
SELECT COUNT(*) FROM measurement;

SELECT c.condition_concept_id
FROM condition_occurrence c
LEFT JOIN concept con
ON c.condition_concept_id = con.concept_id
WHERE con.concept_id IS NULL;


-- 1. Row Count Validation
-- ==============================

SELECT 'PERSON count' AS check_type, COUNT(*) AS total_records FROM person;

SELECT 'VISIT_OCCURRENCE count' AS check_type, COUNT(*) AS total_records FROM visit_occurrence;

SELECT 'CONDITION_OCCURRENCE count' AS check_type, COUNT(*) AS total_records FROM condition_occurrence;

SELECT 'MEASUREMENT count' AS check_type, COUNT(*) AS total_records FROM measurement;



-- ==============================
-- 2. Missing Values Check
-- ==============================

SELECT 'Missing person_id in PERSON' AS check_type, COUNT(*) 
FROM person
WHERE person_id IS NULL;

SELECT 'Missing gender_concept_id in PERSON' AS check_type, COUNT(*)
FROM person
WHERE gender_concept_id IS NULL;

SELECT 'Missing person_id in VISIT_OCCURRENCE' AS check_type, COUNT(*)
FROM visit_occurrence
WHERE person_id IS NULL;

SELECT 'Missing visit_start_date' AS check_type, COUNT(*)
FROM visit_occurrence
WHERE visit_start_date IS NULL;



-- ==============================
-- 3. Referential Integrity Checks
-- ==============================
use omop2
-- Check if VISIT references valid PERSON
SELECT 'Invalid person reference in VISIT_OCCURRENCE' AS check_type, COUNT(*)
FROM visit_occurrence v
LEFT JOIN person p
ON v.person_id = p.person_id
WHERE p.person_id IS NULL;


-- Check if CONDITION references valid VISIT
SELECT 'Invalid visit reference in CONDITION_OCCURRENCE' AS check_type, COUNT(*)
FROM condition_occurrence c
LEFT JOIN visit_occurrence v
ON c.visit_occurrence_id = v.visit_occurrence_id
WHERE v.visit_occurrence_id IS NULL;


-- Check if MEASUREMENT references valid PERSON
SELECT 'Invalid person reference in MEASUREMENT' AS check_type, COUNT(*)
FROM measurement m
LEFT JOIN person p
ON m.person_id = p.person_id
WHERE p.person_id IS NULL;



-- ==============================
-- 4. Invalid Concept ID Checks
-- ==============================

-- CONDITION concept validation
SELECT 'Invalid condition_concept_id' AS check_type, COUNT(*)
FROM condition_occurrence co
LEFT JOIN concept c
ON co.condition_concept_id = c.concept_id
WHERE c.concept_id IS NULL;


-- MEASUREMENT concept validation
SELECT 'Invalid measurement_concept_id' AS check_type, COUNT(*)
FROM measurement m
LEFT JOIN concept c
ON m.measurement_concept_id = c.concept_id
WHERE c.concept_id IS NULL;



-- ==============================
-- 5. Timeline Validation
-- ==============================

-- Visit end date before start date
SELECT 'Invalid visit dates' AS check_type, COUNT(*)
FROM visit_occurrence
WHERE visit_end_date < visit_start_date;



-- ==============================
-- 6. Summary Data Quality Report
-- ==============================

SELECT 
(SELECT COUNT(*) FROM person) AS total_persons,
(SELECT COUNT(*) FROM visit_occurrence) AS total_visits,
(SELECT COUNT(*) FROM condition_occurrence) AS total_conditions,
(SELECT COUNT(*) FROM measurement) AS total_measurements;


-- doubt
	SELECT 
	p.person_id,
	c.concept_name AS gender
	FROM person p
	JOIN concept c
	ON p.gender_concept_id = c.concept_id;


SELECT person_id, gender_concept_id
FROM person;

SELECT concept_id, concept_name
FROM concept
WHERE concept_id IN (
SELECT gender_concept_id FROM person
);
SELECT * FROM concept;
SELECT DISTINCT gender_concept_id
FROM person;
SELECT concept_id, concept_name
FROM concept
WHERE concept_id = 8532
OR concept_id = 8507;
SELECT concept_id, concept_name
FROM concept
WHERE concept_name LIKE '%female%';

SELECT COUNT(*) AS total_concepts
FROM concept;
SELECT DISTINCT vocabulary_id
FROM concept;
SELECT concept_id, concept_name, vocabulary_id
FROM concept
WHERE concept_name LIKE '%diabetes%'
LIMIT 10;

SELECT 
co.condition_occurrence_id,
c.concept_name AS condit
FROM condition_occurrence co
JOIN concept c
ON co.condition_concept_id = c.concept_id;
SELECT
c.concept_id,
c.concept_name,
c.vocabulary_id
FROM concept c
WHERE concept_name LIKE '%diabetes%'
LIMIT 10;

SELECT concept_id, concept_name
FROM concept
WHERE concept_name IN ('Male','Female');

SET GLOBAL local_infile = 1;
SHOW VARIABLES LIKE 'local_infile';

LOAD DATA LOCAL INFILE 'C:/omop_vocab/VOCABULARY'
INTO TABLE vocabulary
FIELDS TERMINATED BY '\t'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;
SELECT COUNT(*) FROM concept;
SELECT concept_id, concept_name
FROM concept
WHERE concept_id = 8532
OR concept_id = 8507;
SELECT p.person_id, c.concept_name
FROM person p
JOIN concept c
ON p.gender_concept_id = c.concept_id;
select * from person
select * from concept





