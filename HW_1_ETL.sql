
USE employees;
-- 1 -----------------------------------------------------------------------------------
DELIMITER //
CREATE PROCEDURE ADD_NEW_EMP(
							 P_BIRTH_DATE DATE,
							 P_FIRST_NAME VARCHAR(14),
                             P_LAST_NAME  VARCHAR(16),
                             P_GENDER     CHAR(1),
                             P_HIRE_DATE  DATE,
                             P_DEPT_NO    CHAR(4),
                             P_SALARY     INT,
                             P_TITLE      VARCHAR(50)
                             )
 BEGIN
	     
		DECLARE P_EMP_NO INT;
        SET P_EMP_NO = (SELECT max(e.emp_no)+1 FROM `employees`.`employees` AS e);  
        
         IF P_TITLE NOT IN (SELECT t.title FROM `employees`.`titles` AS t) 
			THEN
				SIGNAL SQLSTATE '45000'
				SET MESSAGE_TEXT = 'The title does not match available';
		 ELSEIF P_SALARY < 3000
            THEN
				SIGNAL SQLSTATE '45000'
				SET MESSAGE_TEXT = 'The salary is too low';
		 END IF;
		
		INSERT INTO `employees`.`employees`(emp_no, birth_date, first_name, last_name, gender, hire_date)
			VALUES(P_EMP_NO,  P_BIRTH_DATE, P_FIRST_NAME, P_LAST_NAME, P_GENDER, P_HIRE_DATE);
	
		INSERT INTO `employees`.`dept_emp`(emp_no, dept_no, from_date, to_date)
			VALUES(P_EMP_NO, P_DEPT_NO, CURDATE(), '9999-01-01');
    
		INSERT INTO `employees`.`salaries`(emp_no, salary, from_date, to_date)
			VALUES(P_EMP_NO, P_SALARY, CURDATE(), '9999-01-01');
    
		INSERT INTO `employees`.`titles`(emp_no, title, from_date, to_date)
			VALUES(P_EMP_NO, P_TITLE, CURDATE(), '9999-01-01');
 END
 //
 
CALL ADD_NEW_EMP('1998-07-12', 'Alexis', 'Bri','M','2022-10-01','d001',1000,'Staff');
-- 2 -----------------------------------------------------------------------------------
DELIMITER //
CREATE PROCEDURE UPDATE_СUR_SALARY(
								   IN P_EMP_NO INT, 
								   IN P_SALARY INT 
				                  )
BEGIN

        IF P_EMP_NO NOT IN (SELECT s.emp_no FROM `employees`.`salaries` AS s)
			THEN
				SIGNAL SQLSTATE '45000'
				SET MESSAGE_TEXT = 'The employee does not exist';
            END IF;
        
        UPDATE `employees`.`salaries`
          SET to_date = now()
          WHERE emp_no = P_EMP_NO
          ORDER BY to_date DESC
          LIMIT 1; 
         
		INSERT INTO `employees`.`salaries`(emp_no, salary, from_date, to_date)
			VALUES(P_EMP_NO, P_SALARY, now(), '9999-01-01');

END
//

CALL UPDATE_СUR_SALARY(500004, 123456);
-- 3 -----------------------------------------------------------------------------------
DELIMITER //
CREATE PROCEDURE DEL_EMP(
							 P_EMP_NO INT
                             )
 BEGIN
      IF P_EMP_NO NOT IN (SELECT s.emp_no FROM `employees`.`salaries` AS s)
			THEN
				SIGNAL SQLSTATE '45000'
				SET MESSAGE_TEXT = 'The employee does not exist';
	  END IF;
            
		DELETE FROM `employees`.`employees`
			WHERE  emp_no = P_EMP_NO;
		DELETE FROM `employees`.`dept_emp`
			WHERE  emp_no = P_EMP_NO;
		DELETE FROM `employees`.`salaries`
			WHERE  emp_no = P_EMP_NO; 
		DELETE FROM `employees`.`titles` 
			WHERE  emp_no = P_EMP_NO;
 END
 //
 
call DEL_EMP(500050)
-- 4 ----------------------------------------------------------------------------------
DELIMITER //
CREATE FUNCTION GET_CUR_SAL_EMP(
								   P_EMP_NO INT
								  )
RETURNS VARCHAR (50) DETERMINISTIC
BEGIN
	DECLARE V_CUR_SAL VARCHAR(50);
	 SELECT S.SALARY
	  INTO V_CUR_SAL
	  FROM `employees`.`salaries`    AS S  
	  WHERE S.TO_DATE > CURRENT_DATE()
		   AND S.EMP_NO  = P_EMP_NO;
         
	RETURN V_CUR_SAL;
END
//  

SELECT e.*, GET_CUR_SAL_EMP(e.emp_no) AS `CurrentSalary`
 FROM `employees`.`employees` AS e

