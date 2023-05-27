# Globant’s Data Engineering Coding Challenge
Welcome to Globant’s Data Engineering coding challenge!

You will find several different sections in here. Mind that:

* You can choose which sections to solve based on your experience and available time
* if you don’t know how to solve a section, you can proceed with the following one
* You can use whichever language, libraries, and frameworks that you want. 
* The usage of cloud services is allowed, you can choose whichever cloud provider that you want
* Try to always apply best practices and develop a scalable solution.
* We recommend you to solve everything
* If you don’t have time to solve any sections, try to think the toolstack you would like to use and the resulting architecture, and why.
* Every complement you might want to add is highly welcome!
* In case you have a personal github repository to share with the interviewer, please do!

## Section 1: API
In the context of a DB migration with 3 different tables (departments, jobs, employees) , create a local REST API that must:

1.	Receive historical data from CSV files
2.	Upload these files to the new DB
3.	Be able to insert batch transactions (1 up to 1000 rows) with one request

You need to publish your code in GitHub. It will be taken into account if frequent updates are made to the repository that allow analyzing the development process. Ideally, create a markdown file for the Readme.md 

Clarifications 
* You decide the origin where the CSV files are located. 
* You decide the destination database type, but it must be a SQL database.
* The CSV file is comma separated. 

