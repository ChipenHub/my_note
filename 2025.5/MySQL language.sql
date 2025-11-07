## 创建表 primary key unique not null auto_increment default

create table user(
	id int unsigned primary key not null auto_increment,
	name varchar(50) unique not null,
	age tinyint not null,
	sex enum('M', 'W') not null
)engine=INNODB default charset=utf8;


insert into user(name, age, sex) values('zhangsan', 20, 'M');
insert into user(name, age, sex) values('gaoyang', 22, 'M');
insert into user(name, age, sex) values('chenwei', 20, 'M');
insert into user(name, age, sex) values('zhangfan', 21, 'M');
insert into user(name, age, sex) values('zhanglan', 22, 'M');


