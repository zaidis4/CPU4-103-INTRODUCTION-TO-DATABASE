-- Crownfield Eye Hospital: security and transaction demonstrations


USE crownfield_eye;

-- PART D1: Four database roles
CREATE ROLE IF NOT EXISTS 'hospital_admin';
CREATE ROLE IF NOT EXISTS 'hospital_doctor';
CREATE ROLE IF NOT EXISTS 'hospital_receptionist';
CREATE ROLE IF NOT EXISTS 'hospital_patient';

-- PART D2: Role-based access control (mirrors the original demonstration)
GRANT SELECT, INSERT, UPDATE, DELETE ON crownfield_eye.* TO 'hospital_admin';
GRANT SELECT ON crownfield_eye.* TO 'hospital_doctor';
GRANT INSERT, UPDATE ON crownfield_eye.appointment_diagnosis TO 'hospital_doctor';
GRANT INSERT, UPDATE ON crownfield_eye.follow_up TO 'hospital_doctor';
GRANT SELECT, INSERT, UPDATE ON crownfield_eye.patient TO 'hospital_receptionist';
GRANT SELECT, INSERT, UPDATE ON crownfield_eye.appointment TO 'hospital_receptionist';

-- The view restricts COLUMNS, not individual patients' ROWS.
-- This is a classroom demonstration, not safe patient self-service access.
CREATE OR REPLACE VIEW patient_appointment_view AS
SELECT appointment_id, appointment_date, appointment_time, clinic_id
FROM appointment;
GRANT SELECT ON crownfield_eye.patient_appointment_view TO 'hospital_patient';

-- Inspect effective role grants.
SHOW GRANTS FOR 'hospital_admin';
SHOW GRANTS FOR 'hospital_doctor';
SHOW GRANTS FOR 'hospital_receptionist';
SHOW GRANTS FOR 'hospital_patient';

-- PART D3: Optional account test (perform manually, not in this script).
-- Create a separate local account using a strong, unique password entered
-- outside the version-controlled file, then grant hospital_patient and set
-- its default role. In that account's OWN connection, verify:
--   SELECT * FROM crownfield_eye.patient_appointment_view LIMIT 5; -- allowed
--   SELECT * FROM crownfield_eye.patient; -- expected Error 1142
-- Do not use the root connection to test restricted access.

-- PART D4: AES encryption applied to a STORED fictional sensitive field.
-- This demonstration table is separate from the 11 core ERD tables.
-- It is intended to strengthen the earlier expression-only AES demonstration.
CREATE TABLE IF NOT EXISTS encrypted_note_demo (
    demo_note_id INT PRIMARY KEY,
    encrypted_note VARBINARY(1024) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;


SET @demo_aes_key = RANDOM_BYTES(32);

-- Insert encrypted data into an actual column (no plaintext stored there).
INSERT INTO encrypted_note_demo (demo_note_id, encrypted_note)
VALUES (90001, AES_ENCRYPT('Fictional Patient Note', @demo_aes_key))
ON DUPLICATE KEY UPDATE encrypted_note = VALUES(encrypted_note);

-- Verify the stored value is encrypted, then decrypt in the SAME session.
SELECT demo_note_id, HEX(encrypted_note) AS encrypted_hex
FROM encrypted_note_demo WHERE demo_note_id = 90001;
SELECT demo_note_id,
       CAST(AES_DECRYPT(encrypted_note, @demo_aes_key) AS CHAR) AS decrypted_note
FROM encrypted_note_demo WHERE demo_note_id = 90001;

-- Clear the key variable after the demonstration.
SET @demo_aes_key = NULL;

-- PART D5: COMMIT / ROLLBACK 
CREATE TABLE IF NOT EXISTS transaction_demo (
    demo_id INT PRIMARY KEY,
    description VARCHAR(100) NOT NULL
) ENGINE=InnoDB;


DELETE FROM transaction_demo WHERE demo_id IN (90101, 90102);

START TRANSACTION;
INSERT INTO transaction_demo (demo_id, description)
VALUES (90101, 'Rollback Test');
SELECT * FROM transaction_demo WHERE demo_id = 90101; -- visible in transaction
ROLLBACK;
SELECT * FROM transaction_demo WHERE demo_id = 90101; -- no rows

START TRANSACTION;
INSERT INTO transaction_demo (demo_id, description)
VALUES (90102, 'Commit Test');
COMMIT;
SELECT * FROM transaction_demo WHERE demo_id = 90102; -- one saved row

