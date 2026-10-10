CREATE DATABASE EMPLOYEE_MANAGEMENT;
USE EMPLOYEE_MANAGEMENT;

-- Table 1: Job Department
CREATE TABLE JobDepartment (
Job_ID INT PRIMARY KEY,
jobdept VARCHAR(50),
name VARCHAR(100),
description TEXT,
salaryrange VARCHAR(50)
);

DESC JobDepartment;
SELECT * FROM JOBDEPARTMENT;

-- JOB ROLE AND DEPARTMENT ANALYSIS
# How many different job roles exist in each department?
SELECT JOBDEPT AS DEPARTMENT,
COUNT(DISTINCT NAME) AS JOB_ROLE_COUNT
FROM JOBDEPARTMENT
GROUP BY DEPARTMENT
ORDER BY JOB_ROLE_COUNT DESC;

# What is the average salary range per department?
SELECT
    jobdept AS department,
    ROUND(
        AVG(
            (
                CAST(REPLACE(SUBSTRING_INDEX(salaryrange, '-', -1), '$', '') AS DECIMAL(10,2))
                -
                CAST(REPLACE(SUBSTRING_INDEX(salaryrange, '-', 1), '$', '') AS DECIMAL(10,2))
            )
        ), 2
    ) AS average_salary_range
FROM JobDepartment
GROUP BY jobdept
ORDER BY average_salary_range DESC;

# Which job roles offer the highest salary?
SELECT JD.NAME AS JOB_ROLE, 
JD.JOBDEPT AS DEPARTMENT,
S.AMOUNT AS SALARY
FROM JOBDEPARTMENT JD
JOIN SALARYBONUS S
ON JD.JOB_ID=S.JOB_ID
ORDER BY SALARY DESC
LIMIT 1;

# Which departments have the highest total salary allocation?
SELECT JD.JOBDEPT AS DEPARTMENT,
SUM(S.AMOUNT) AS TOTAL_SALARY_ALLOCATION
FROM JOBDEPARTMENT JD
JOIN SALARYBONUS S
ON JD.JOB_ID = S.JOB_ID
GROUP BY DEPARTMENT
ORDER BY TOTAL_SALARY_ALLOCATION DESC;




-- Table 2: Salary/Bonus
CREATE TABLE SalaryBonus (
salary_ID INT PRIMARY KEY,
Job_ID INT,
amount DECIMAL(10,2),
annual DECIMAL(10,2),
bonus DECIMAL(10,2),
CONSTRAINT fk_salary_job FOREIGN KEY (job_ID) REFERENCES JobDepartment(Job_ID)
ON DELETE CASCADE ON UPDATE CASCADE
);
DESC SalaryBonus;
SELECT * FROM SalaryBonus;


-- Table 3: Employee
CREATE TABLE Employee (
emp_ID INT PRIMARY KEY,
firstname VARCHAR(50),
lastname VARCHAR(50),
gender VARCHAR(10),
age INT,
contact_add VARCHAR(100),
emp_email VARCHAR(100) UNIQUE,
emp_pass VARCHAR(50),
Job_ID INT,
CONSTRAINT fk_employee_job FOREIGN KEY (Job_ID)
REFERENCES JobDepartment(Job_ID)
ON DELETE SET NULL
ON UPDATE CASCADE
);
DESC Employee;
SELECT * FROM Employee;

-- EMPLOYEE INSIGHTS
# How many unique employees are currently in the system?
SELECT COUNT(DISTINCT emp_ID) AS unique_employees
FROM Employee;

# ● Which departments have the highest number of employees?
SELECT JD.JOBDEPT AS JOB_DEPT, COUNT(E.EMP_ID) AS EMP_COUNT
FROM EMPLOYEE AS E
JOIN JOBDEPARTMENT AS JD
ON E.JOB_ID = JD.JOB_ID
GROUP BY JOB_DEPT 
ORDER BY EMP_COUNT DESC;

# What is the average salary per department?
SELECT JD.JOBDEPT AS JOB_DEPT, ROUND(AVG(S.AMOUNT),2) AS AVG_SAL
FROM SalaryBonus AS S
JOIN JOBDEPARTMENT AS JD
ON S.JOB_ID = JD.JOB_ID
GROUP BY JOB_DEPT 
ORDER BY AVG_SAL DESC;

# Who are the top 5 highest-paid employees?
SELECT CONCAT(E.FIRSTNAME, ' ', E.LASTNAME) AS EMP_NAME, JD.JOBDEPT AS JOB_DEPT, S.AMOUNT  AS HIGHEST_PAID_EMP
FROM EMPLOYEE E
JOIN JOBDEPARTMENT AS JD
ON E.JOB_ID = JD.JOB_ID
JOIN SALARYBONUS AS S
ON JD.JOB_ID = S.JOB_ID
ORDER BY HIGHEST_PAID_EMP DESC
LIMIT 5;

# What is the total salary expenditure across the company?
SELECT SUM(amount) AS total_salary_expenditure
FROM SalaryBonus;


-- Table 4: Qualification
CREATE TABLE Qualification (
QualID INT PRIMARY KEY,
Emp_ID INT,
Position VARCHAR(50),
Requirements VARCHAR(255),
Date_In DATE,
CONSTRAINT fk_qualification_emp FOREIGN KEY (Emp_ID)
REFERENCES Employee(emp_ID)
ON DELETE CASCADE
ON UPDATE CASCADE
);
DESC Qualification;
SELECT * FROM Qualification;


-- QUALIFICATION AND SKILLS ANALYSIS
# How many employees have at least one qualification listed?
SELECT COUNT(DISTINCT EMP_ID) AS EMPLOYEE_WITH_QUALIFICATION
FROM QUALIFICATION;

# Which positions require the most qualifications?
SELECT POSITION,
COUNT(QUALID) AS QUALIFICATION_COUNT
FROM QUALIFICATION
GROUP BY POSITION
ORDER BY QUALIFICATION_COUNT DESC;

# Which employees have the highest number of qualifications?
SELECT E.EMP_ID,
CONCAT(E.FIRSTNAME, ' ', E.LASTNAME)AS EMPLOYEE_NAME,
COUNT(Q.QUALID) AS QUALIFICATION_COUNT
FROM EMPLOYEE E
JOIN QUALIFICATION Q
ON E.EMP_ID = Q.EMP_ID
GROUP BY E.EMP_ID, E.FIRSTNAME, E.LASTNAME
ORDER BY QUALIFICATION_COUNT DESC;



-- Table 5: Leaves
CREATE TABLE Leaves (
leave_ID INT PRIMARY KEY,
emp_ID INT,
date DATE,
reason TEXT,
CONSTRAINT fk_leave_emp FOREIGN KEY (emp_ID) REFERENCES Employee(emp_ID)
ON DELETE CASCADE ON UPDATE CASCADE
);
DESC Leaves;
SELECT * FROM Leaves;


-- LEAVE AND ABSENCE PATTERNS
# Which year had the most employees taking leaves?
SELECT YEAR(DATE) AS LEAVE_YEAR,
COUNT(DISTINCT EMP_ID) AS EMPLOYEES_ON_LEAVE
FROM LEAVES
GROUP BY YEAR(DATE)
ORDER BY EMPLOYEES_ON_LEAVE DESC
LIMIT 1;

# What is the average number of leave days taken by its employees per department?
SELECT JD.JOBDEPT AS DEPARTMENT,
ROUND(COUNT(L.LEAVE_ID) / COUNT(DISTINCT E.EMP_ID), 2) AS AVG_LEAVE_DAYS
FROM EMPLOYEE AS E
JOIN JOBDEPARTMENT AS JD
ON E.JOB_ID = JD.JOB_ID
LEFT JOIN LEAVES AS L 
ON E.EMP_ID = L.EMP_ID
GROUP BY JD.JOBDEPT
ORDER BY AVG_LEAVE_DAYS DESC;

# Which employees have taken the most leaves?
SELECT E.EMP_ID,
CONCAT(E.FIRSTNAME, ' ', E.LASTNAME) AS EMPLOYEE_NAME,
COUNT(L.LEAVE_ID) AS TOTAL_LEAVES
FROM EMPLOYEE AS E
JOIN LEAVES AS L
ON E.EMP_ID = L.EMP_ID
GROUP BY E.EMP_ID, E.FIRSTNAME, E.LASTNAME 
ORDER BY TOTAL_LEAVES DESC;
 
# What is the total number of leave days taken company-wide?
SELECT COUNT(LEAVE_ID) AS TOTAL_LEAVE_DAYS
FROM LEAVES;

# How do leave days correlate with payroll amounts?
SELECT
    e.emp_ID,
    CONCAT(e.firstname, ' ', e.lastname) AS employee_name,
    COALESCE(l.total_leaves, 0) AS total_leaves,
    sb.amount AS monthly_salary,
    ROUND(
        (sb.amount / 30) * COALESCE(l.total_leaves, 0),
        2
    ) AS salary_deducted,
    ROUND(
        sb.amount - ((sb.amount / 30) * COALESCE(l.total_leaves, 0)),
        2
    ) AS salary_after_deduction
FROM Employee e
LEFT JOIN (
    SELECT
        emp_ID,
        COUNT(leave_ID) AS total_leaves
    FROM Leaves
    GROUP BY emp_ID
) l
    ON e.emp_ID = l.emp_ID
LEFT JOIN SalaryBonus sb
    ON e.Job_ID = sb.Job_ID
ORDER BY total_leaves DESC;



-- Table 6: Payroll
CREATE TABLE Payroll (
payroll_ID INT PRIMARY KEY,
emp_ID INT,
job_ID INT,
salary_ID INT,
leave_ID INT,
date DATE,
report TEXT,
total_amount DECIMAL(10,2),
CONSTRAINT fk_payroll_emp FOREIGN KEY (emp_ID) REFERENCES Employee(emp_ID)
ON DELETE CASCADE ON UPDATE CASCADE,
CONSTRAINT fk_payroll_job FOREIGN KEY (job_ID) REFERENCES JobDepartment(job_ID)
ON DELETE CASCADE ON UPDATE CASCADE,
CONSTRAINT fk_payroll_salary FOREIGN KEY (salary_ID) REFERENCES
SalaryBonus(salary_ID)
ON DELETE CASCADE ON UPDATE CASCADE,
CONSTRAINT fk_payroll_leave FOREIGN KEY (leave_ID) REFERENCES Leaves(leave_ID)
ON DELETE SET NULL ON UPDATE CASCADE
);
DESC Payroll;
SELECT * FROM Payroll;

-- PAYROLL AND COMPENSATION ANALYSIS
# What is the total monthly payroll processed?
SELECT SUM(TOTAL_AMOUNT) AS TOTAL_MONTHLY_PAYROLL
FROM PAYROLL;

# What is the average bonus given per department?
SELECT JD.JOBDEPT AS DEPARTMENT,
AVG(S.BONUS) AS AVERAGE_BONUS
FROM JOBDEPARTMENT AS JD
JOIN SALARYBONUS AS S
ON JD.JOB_ID = S.JOB_ID
GROUP BY JD.JOBDEPT
ORDER BY AVERAGE_BONUS DESC;


# Which department receives the highest total bonuses?
SELECT JD.JOBDEPT AS DEPARTMENT,
SUM(S.BONUS) AS TOTAL_BONUS
FROM JOBDEPARTMENT AS JD
JOIN SALARYBONUS AS S
ON JD.JOB_ID = S.JOB_ID
GROUP BY JD.JOBDEPT
ORDER BY TOTAL_BONUS DESC
LIMIT 1;

# What is the average value of total_amount after considering leave deductions?
SELECT AVG(TOTAL_AMOUNT) AS AVERAGE_PAYROLL_AFTER_LEAVE_DEDUCTIONS
FROM PAYROLL;

