drop database if exists itmo;
create database itmo;
\c itmo;

create table Students (
    student_id int PRIMARY KEY,
    student_name varchar(50) NOT NULL,
    group_id int
);

create table Teachers (
    teacher_id int PRIMARY KEY,
    teacher_name varchar(50) NOT NULL
);

create table Courses (
    course_id int PRIMARY KEY,
    course_name varchar(50) NOT NULL,
    term_id int NOT NULL,
    teacher_id int,
    UNIQUE (course_name, term_id)
);

create table StudyProgram (
    group_id int,
    course_id int,
    PRIMARY KEY (group_id, course_id)
);

create table Groups (
    group_id int PRIMARY KEY,
    group_name char(5) NOT NULL,
    course_id int
);

create table Points (
    student_id int,
    course_id int,
    points DECIMAL(10, 2) NOT NULL,
    PRIMARY KEY (student_id, course_id)
);

alter table Courses add FOREIGN KEY (teacher_id)
    REFERENCES Teachers (teacher_id);
alter table StudyProgram add FOREIGN KEY (group_id)
    REFERENCES Groups (group_id);
alter table StudyProgram add FOREIGN KEY (course_id)
    REFERENCES Courses (course_id);
alter table Groups add FOREIGN KEY (group_id, course_id)
    REFERENCES StudyProgram (group_id, course_id);
alter table Students add FOREIGN KEY (group_id)
    REFERENCES Groups (group_id);
alter table Points add FOREIGN KEY (student_id)
    REFERENCES Students (student_id);
alter table Points add FOREIGN KEY (course_id)
    REFERENCES Courses (course_id);

insert into Students (student_name, student_id) values ('Филиппов Дмитрий', 1), ('Пересадин Илья', 2), ('Замятин Евгений', 3);
select * from Students;

insert into Teachers (teacher_name, teacher_id) values ('Додонов Николай', 1), ('Корнеев Георгий', 2), ('Станкевич Андрей', 3);
select * from Teachers;

insert into Courses
    (course_name, course_id, term_id, teacher_id) values
    ('Функциональный анализ', 1, 6, 1),
    ('Базы данных', 2, 7, 2),
    ('Алгоритмы и структуры данных', 3, 3, 3);
select * from Courses;

insert into Groups (group_name, group_id) values ('M3439', 1), ('M3438', 2);
select * from Groups;

insert into StudyProgram (group_id, course_id) values (1, 1), (1, 2), (1, 3), (2, 1), (2, 3);
select * from StudyProgram;

--should fail
update Groups set course_id = 2 where group_name = 'M3438';
select * from Groups;

insert into Points (student_id, course_id, points) values (1, 1, 92.01), (1, 2, 84.15);
select * from Points;

select student_name, points from Students natural join Points;
select group_name, course_id, group_id from Groups natural join StudyProgram;
