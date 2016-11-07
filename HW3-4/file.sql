drop database if exists itmo;
create database itmo;
\c itmo;

create table Students (
    student_id int NOT NULL PRIMARY KEY,
    student_name varchar(100) NOT NULL,
    group_id int NOT NULL
);

create table Lecturers (
    lecturer_id int NOT NULL PRIMARY KEY,
    lecturer_name varchar(100) NOT NULL
);

create table Courses (
    course_id int NOT NULL PRIMARY KEY,
    course_name varchar(100) NOT NULL,
    lecturer_id int NOT NULL,
    UNIQUE (course_name, lecturer_id)
);

create table StudyProgram (
    lecturer_id int NOT NULL,
    course_id int NOT NULL,
    group_id int NOT NULL,
    PRIMARY KEY (group_id, course_id, lecturer_id)
);

create table Groups (
    group_id int NOT NULL PRIMARY KEY,
    group_name char(5) NOT NULL
);

create table Marks (
    student_id int NOT NULL,
    course_id int NOT NULL,
    mark int NOT NULL,
    PRIMARY KEY (student_id, course_id)
);

alter table StudyProgram add FOREIGN KEY (lecturer_id)
    REFERENCES Lecturers (lecturer_id);
alter table StudyProgram add FOREIGN KEY (course_id)
    REFERENCES Courses (course_id);
alter table StudyProgram add FOREIGN KEY (group_id)
    REFERENCES Groups (group_id);
alter table Marks add FOREIGN KEY (student_id)
    REFERENCES Students (student_id);
alter table Marks add FOREIGN KEY (course_id)
    REFERENCES Courses (course_id);
alter table Students add FOREIGN KEY (group_id)
    REFERENCES Groups (group_id);

insert into Groups (group_name, group_id) values ('M3439', 1), ('M3438', 2);
select * from Groups;

insert into Students (student_name, student_id, group_id) values ('Филиппов Дмитрий', 1, 1), ('Пересадин Илья', 2, 1), ('Замятин Евгений', 3, 2), ('Яковлева Дарья', 4, 2);
select * from Students;

insert into Lecturers (lecturer_name, lecturer_id) values ('Додонов Николай', 1), ('Корнеев Георгий', 2), ('Станкевич Андрей', 3);
select * from Lecturers;

insert into Courses
    (course_name, course_id, lecturer_id) values
    ('Функциональный анализ', 1, 1),
    ('Базы данных', 2, 2),
    ('Алгоритмы и структуры данных', 3, 3);
select * from Courses;

insert into StudyProgram (group_id, course_id, lecturer_id) values (1, 1, 1), (1, 2, 3), (1, 3, 2), (2, 1, 2), (2, 3, 1);
select * from StudyProgram;

insert into Marks (student_id, course_id, mark) values (1, 1, 4), (1, 2, 5);
select * from Marks;

select student_name, mark from Students natural join Marks;
select group_name, course_id, group_id from Groups natural join StudyProgram;
