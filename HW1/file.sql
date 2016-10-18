drop database if exists ctd;
drop table if exists students;
drop table if exists groups;

create database CTD;

create table Groups (
  group_id int,
  group_no char(5)
);

create table Students (
  student_id int,
  name varchar(30),
  group_id int
);

insert into Groups
    (group_id, group_no) values
    (1, 'M3438'),
    (2, 'M3439');

insert into Students
    (student_id, name, group_id) values
    (1, 'Ruslan Ahundov', 1),
    (2, 'Pavel Asadchy', 2),
    (3, 'Eugene Varlamov', 2);

alter table Groups
    add constraint group_id_unique unique (group_id);

alter table Students add foreign key (group_id)
    references Groups (group_id);

/*select group_id, group_no from Groups;

select student_id, name, group_id from Students;

select name, group_no
    from Students natural join Groups;
select Students.name, Groups.group_no
    from Students 
         inner join Groups 
         on Students.group_id = Groups.group_id;
*/

insert into Students 
  (student_id, name, group_id) values
  (4, 'Иван Петров', 1),
  (5, 'Иван Сидоров', 1),
  (6, 'Яков Сергей', 1);

select count(*) from Groups;
select count(*) from Students;
select count(*) from Students where name like '%ван%' or name like '%ов';

delete from Groups;
delete from Students;
delete from Groups;

insert into Groups (group_id, group_no) values
  (1, 'M3137'),
  (2, 'M3138'),
  (3, 'M3139');

insert into Students (student_id, name, group_id) values
  (1, 'Никита Гусак', 1),
  (2, 'Евгений Немченко', 2),
  (3, 'Никита Ященко', 2),
  (4, 'Илья Пересадин', 3),
  (5, 'Евгений Замятин', 3),
  (6, 'Григорий Шовкопляс', 3);

select group_no, count(*) from Groups inner join Students on Groups.group_id = Students.group_id group by group_no order by group_no desc;