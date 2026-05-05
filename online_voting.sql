CREATE DATABASE online_voting;
USE online_voting;

-- -------------------------------- Elections Table ----------------------------
CREATE TABLE elections (
    election_id VARCHAR(15) PRIMARY KEY,
    election_name VARCHAR(150) NOT NULL,
    start_date DATE,
    end_date DATE,
    status ENUM('Ongoing','Completed') NOT NULL
);

INSERT INTO elections VALUES
('LS-2024','Lok Sabha General Election 2024','2024-04-10','2024-05-20','Completed'),
('MH-2024','Maharashtra Vidhan Sabha Election 2024','2024-10-01','2024-10-10','Completed'),
('PUNE-2026','Pune Municipal Corporation Election 2026','2026-02-01','2026-02-10','Ongoing');

-- ------------------------------------ Voters Table --------------------------------
CREATE TABLE voters (
    voter_id INT PRIMARY KEY AUTO_INCREMENT,
    voter_name VARCHAR(100) NOT NULL,
    date_of_birth DATE NOT NULL,
    gender VARCHAR(10),
    address VARCHAR(255),
    email VARCHAR(100) UNIQUE,
    password VARCHAR(255),
    voting_status ENUM('Not Voted','Voted') DEFAULT 'Not Voted'
);

INSERT INTO voters(voter_name, date_of_birth, gender, address, email, password)
VALUES
('Manisha Deshmukh','2003-05-15','Female','Pune, Maharashtra','manisha@gmail.com','pass123'),
('Rahul Patil','2002-08-20','Male','Mumbai, Maharashtra','rahul@gmail.com','pass123'),
('Priya Sharma','2001-11-10','Female','Nagpur, Maharashtra','priya@gmail.com','pass123'),
('Amit Joshi','2000-02-18','Male','Nashik, Maharashtra','amit@gmail.com','pass123'),
('Sneha Kulkarni','1999-07-25','Female','Pune, Maharashtra','sneha@gmail.com','pass123');

-- ------------------------------------ Candidates Table -------------------------------
CREATE TABLE candidates (
    candidate_id VARCHAR(10) PRIMARY KEY,
    candidate_name VARCHAR(100) NOT NULL,
    party_name VARCHAR(100) NOT NULL,
    age INT,
    constituency VARCHAR(100),
    state VARCHAR(100),
    election_id VARCHAR(15),
    FOREIGN KEY (election_id) REFERENCES elections(election_id)
);

-- ---------------------------------------------- Lok Sabha ----------------------------
INSERT INTO candidates VALUES
('L101','Amit Shah','BJP',60,'Gandhinagar','Gujarat','LS-2024'),
('L102','Rahul Gandhi','INC',55,'Wayanad','Kerala','LS-2024'),
('L103','Arvind Kejriwal','AAP',57,'New Delhi','Delhi','LS-2024');

-------------------------------- Maharashtra Vidhan Sabha ----------------------
INSERT INTO candidates VALUES
('M201','Devendra Fadnavis','BJP',54,'Nagpur South West','Maharashtra','MH-2024'),
('M202','Uddhav Thackeray','Shiv Sena',63,'Mumbai','Maharashtra','MH-2024'),
('M203','Supriya Sule','NCP',55,'Baramati','Maharashtra','MH-2024');

-- ----------------------------- Pune Municipal --------------------
INSERT INTO candidates VALUES
('P301','Anita Deshmukh','BJP',42,'Kothrud','Maharashtra','PUNE-2026'),
('P302','Rohan Patil','INC',38,'Kothrud','Maharashtra','PUNE-2026');

-- ----------------------------------- Admin Table ---------------------------------
CREATE TABLE admins (
    admin_id INT PRIMARY KEY AUTO_INCREMENT,
    admin_name VARCHAR(100),
    email VARCHAR(100) UNIQUE,
    password VARCHAR(255)
);

INSERT INTO admins (admin_name,email,password) VALUES
('System Admin','admin@onlinevoting.com','admin123'),
('Election Officer','officer@onlinevoting.com','officer123');

-- --------------------------------- Age Validation Trigger (18+ Only) ------------------------
DELIMITER //

CREATE TRIGGER check_voter_age
BEFORE INSERT ON voters
FOR EACH ROW
BEGIN
    IF TIMESTAMPDIFF(YEAR, NEW.date_of_birth, CURDATE()) < 18 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Voter must be 18 years or older';
    END IF;
END //
DELIMITER ;

-- ----------- Votes Table --------------
CREATE TABLE votes (
    vote_id INT PRIMARY KEY AUTO_INCREMENT,
    voter_id INT,
    candidate_id VARCHAR(10),
    election_id VARCHAR(15),
    vote_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (voter_id) REFERENCES voters(voter_id),
    FOREIGN KEY (candidate_id) REFERENCES candidates(candidate_id),
    FOREIGN KEY (election_id) REFERENCES elections(election_id),
    UNIQUE (voter_id, election_id)
);

-- ------------------------------ Candidate Validation Trigger --------------------

DELIMITER //

CREATE TRIGGER validate_candidate_election
BEFORE INSERT ON votes
FOR EACH ROW
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM candidates
        WHERE candidate_id = NEW.candidate_id
        AND election_id = NEW.election_id
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Candidate does not belong to this election';
    END IF;
END //

DELIMITER ;




-- -----------------------------------Auto Update Voting Status --------------------

DELIMITER //

CREATE TRIGGER update_voting_status
AFTER INSERT ON votes
FOR EACH ROW
BEGIN
    UPDATE voters
    SET voting_status = 'Voted'
    WHERE voter_id = NEW.voter_id;
END //
DELIMITER ;

-- ----------------------------------- Insert Votes ----------------------
INSERT INTO votes (voter_id, candidate_id, election_id) VALUES
(1,'L101','LS-2024'),
(2,'L102','LS-2024'),
(3,'P302','PUNE-2026'),
(5,'L103','LS-2024');

-- ------------------------------- add voter -----------------------
INSERT INTO voters 
(voter_name, date_of_birth, gender, address, email, password)
VALUES
('Kunal Patil','2003-09-10','Male','Satara, Maharashtra','kunal@gmail.com','pass123'),
('Neha Sharma','2001-01-05','Female','Thane, Maharashtra','neha@gmail.com','pass123');

-- ------------------------ add votes ---------------
INSERT INTO votes (voter_id, candidate_id, election_id)
VALUES (6,'L101','LS-2024');

-- ------------------------------ Count Votes Per Candidate ----------------------
SELECT c.candidate_name, COUNT(v.vote_id) AS total_votes
FROM candidates c
LEFT JOIN votes v ON c.candidate_id = v.candidate_id
GROUP BY c.candidate_name;

-- ------------------------------- Vote Percentage ------------------------------
SELECT 
    c.candidate_name,
    c.party_name,
    e.election_name,
    COUNT(v.vote_id) AS total_votes,
    ROUND((COUNT(v.vote_id) /
        (SELECT COUNT(*) FROM votes WHERE election_id = c.election_id)
        ) * 100,2
    ) AS vote_percentage
FROM candidates c
LEFT JOIN votes v ON c.candidate_id = v.candidate_id
JOIN elections e ON c.election_id = e.election_id
GROUP BY c.candidate_id;

 -- ------------------------------ Create View ---------------------
CREATE VIEW election_results AS
SELECT 
    c.candidate_name,
    c.party_name,
    e.election_name,
    COUNT(v.vote_id) AS total_votes
FROM candidates c
LEFT JOIN votes v ON c.candidate_id = v.candidate_id
JOIN elections e ON c.election_id = e.election_id
GROUP BY c.candidate_id;

SELECT * FROM election_results;
-- ----------------------------------------------- QUESTION-ANSWER --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- -- 1 Add New Column (phone_number)---
ALTER TABLE voters ADD phone_number VARCHAR(15);

-- -- 2 Modify address Data Type
ALTER TABLE voters MODIFY address VARCHAR(500);

-- ---- 3Insert Candidate for Election
INSERT INTO candidates
(candidate_id, candidate_name, party_name, age, constituency, state, election_id)
VALUES ('P303','Kiran Jadhav','NCP',40,'Shivajinagar','Maharashtra','PUNE-2026');

-- -- 4 Display Ongoing Elections
SELECT * FROM elections WHERE status = 'Ongoing';

-- --- 5 Stored Procedure – Vote Count for Specific Candidate
DELIMITER //
CREATE PROCEDURE get_candidate_votes(IN cid VARCHAR(10))
BEGIN
    SELECT candidate_id, COUNT(*) AS total_votes
    FROM votes
    WHERE candidate_id = cid
    GROUP BY candidate_id;
END //
DELIMITER ;
CALL get_candidate_votes('L102');

-- ---- 6stored procedure to display results of a particular election

DELIMITER //

CREATE PROCEDURE get_election_results(IN eid VARCHAR(15))
BEGIN
    SELECT c.candidate_name, COUNT(v.vote_id) AS total_votes
    FROM candidates c
    LEFT JOIN votes v ON c.candidate_id = v.candidate_id
    WHERE c.election_id = eid
    GROUP BY c.candidate_name;
END //
DELIMITER ;
CALL get_election_results('MH-2024');

-- ---- 7window function to rank candidates based on vote count.
SELECT 
    candidate_id,
    COUNT(*) AS total_votes,
    RANK() OVER (ORDER BY COUNT(*) DESC) AS ranking
FROM votes
GROUP BY candidate_id;

-- -- 8 Event – Auto Close Election After End Date
SET GLOBAL event_scheduler = ON;
CREATE EVENT close_elections
ON SCHEDULE EVERY 1 DAY
DO
UPDATE elections
SET status = 'Completed'
WHERE end_date < CURDATE();






