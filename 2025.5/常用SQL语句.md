# 后端开发 MySQL 技术

---

SQL 是结构化查询语言，他是关系型数据库的通用语言

SQL 可以分为分为以下三个类别

+ DDL (data definition languages) 语句
  + 数据定义语言，定义了 不同的数据库、表、索引等数据库对象的定义。常用的的语句关键字包括 **create、drop、alter **等。
+ DML (data manipulation language) 语句
  + 数据操纵语句，用于添加、删除、更新、和查询数据库记录，并 检查数据完整性。常用的的语句关键字包括 **insert、delete、update、select **等。
+ DCL (data control language) 语句
  + 数据控制语句，用于控制和许可不同的访问级别的语句。这些语句定义了数据库、表、字段、用户的访问权限和安全级别。常用的的语句关键字包括 **grant、revoke**等。

## 库操作

查询数据库	`show databases;` 
创建数据库	`create databases chatDB;`
删除数据库	`drop database chatDB;`
选择数据库	`use chatDB`

演示：

```mysql
mysql> create table user(
    -> id int unsigned primary key not null auto_increment,
    -> name varchar(50) unique not null,
    -> age tinyint not null,
    -> sex enum('M', 'W') not null
    -> )engine=INNODB default charset=utf8;
Query OK, 0 rows affected, 1 warning (0.01 sec)

mysql> desc user;
+-------+---------------+------+-----+---------+---------------+
| Field | Type          | Null | Key | Default | Extra         |
+-------+---------------+------+-----+---------+---------------+
| id    | int unsigned  | NO   | PRI | NULL    | auto_incremet |
| name  | varchar(50)   | NO   | UNI | NULL    |               |
| age   | tinyint       | NO   |     | NULL    |               |
| sex   | enum('M','W') | NO   |     | NULL    |               |
+-------+---------------+------+-----+---------+---------------+
4 rows in set (0.00 sec)
```



## MySQL 核心 SQL

### insert 增加

```mysql
insert into user(name, age, sex) values('zhangsan', 20, 'M');
```

### delete 删除

```mysql
delete from user where id = 1;
```

### update 修改

```mysql
update user set age = age + 1;
```

### selece  查询

```mysql
select name, age, sex from user where age > 20 and age < 22;
select name, age, sex from user where name like "zhang%";
select * from user where age > 21;
```

+ distinct 去重	`select * from user where age > 21;`

+ union all 合并两个表	`select name, sex, age from user union all select name, sex, age from user where sex = 'M';`
  + union 自带去重，加上`all`不去重。


#### 分页查询

```mysql
select * from user limit M, N;
select * from user limit N, offset N;
```

explain 显示 SQL 的查询计划；SQL 为经常搜索的字段添加了索引。

索引搜索

```mysql
mysql> explain select * from user where name = 'zhangsan'\G
*************************** 1. row ***************************
           id: 1
  select_type: SIMPLE
        table: user
   partitions: NULL
         type: const	# 常量
possible_keys: name
          key: name		# 触发索引
      key_len: 152
          ref: const
         rows: 1
     filtered: 100.00
        Extra: NULL
1 row in set, 1 warning (0.00 sec)
```

整表搜索

```mysql
mysql> explain select * from user where age = 23\G
*************************** 1. row ***************************
           id: 1
  select_type: SIMPLE
        table: user
   partitions: NULL
         type: ALL	# 整表搜索
possible_keys: NULL
          key: NULL
      key_len: NULL
          ref: NULL
         rows: 5
     filtered: 20.00
        Extra: Using where
1 row in set, 1 warning (0.00 sec)
```

**注意**：explain 生成的计划仅供参考，不能展示出 SQL 进行的优化

例如：在大量数据中查询时，如果不添加 limit

```shell
mysql> select * from t_user where password = 1;
+---------+--------------+----------+
| id      | email        | password |
+---------+--------------+----------+
| 1000001 | 1@fixbug.com | 1        |
+---------+--------------+----------+
1 row in set (0.21 sec)
#此时查询时间为 0.21 秒


mysql> explain select * from t_user where password = 1\G
*************************** 1. row ***************************
           id: 1
  select_type: SIMPLE
        table: t_user
   partitions: NULL
         type: ALL
possible_keys: NULL
          key: NULL
      key_len: NULL
          ref: NULL
         rows: 1995777	# 显示为遍历了所有数据
     filtered: 10.00
        Extra: Using where
1 row in set, 1 warning (0.00 sec)
```

添加 limit 后

```shell
mysql> select * from t_user where password = 1 limit 1;
+---------+--------------+----------+
| id      | email        | password |
+---------+--------------+----------+
| 1000001 | 1@fixbug.com | 1        |
+---------+--------------+----------+
1 row in set (0.00 sec)
# 查询速度显著增加



mysql> explain select * from t_user where password = 1 limit 1\G
*************************** 1. row ***************************
           id: 1
  select_type: SIMPLE
        table: t_user
   partitions: NULL
         type: ALL
possible_keys: NULL
          key: NULL
      key_len: NULL
          ref: NULL
         rows: 1995777	# 仍然显示遍历了所有数据
     filtered: 10.00
        Extra: Using where
1 row in set, 1 warning (0.00 sec)

```

可见，explain 不能解释 SQL 的优化策略。但添加 limit 可以提高 SQL 的搜索效率。

**快速分页查询**：借助 id 索引查询。

```shell
mysql> select * from t_user where id = 1099994;
+---------+------------------+----------+
| id      | email            | password |
+---------+------------------+----------+
| 1099994 | 99994@fixbug.com | 99994    |
+---------+------------------+----------+
1 row in set (0.00 sec)	# 从速度可以看出 id 自带索引

# 快速分页
mysql> select * from t_user where id > 1100000 limit 20;
+---------+-------------------+----------+
| id      | email             | password |
+---------+-------------------+----------+
| 1100001 | 100001@fixbug.com | 100001   |
| 1100002 | 100002@fixbug.com | 100002   |
| 1100003 | 100003@fixbug.com | 100003   |
| 1100004 | 100004@fixbug.com | 100004   |
| 1100005 | 100005@fixbug.com | 100005   |
| 1100006 | 100006@fixbug.com | 100006   |
| 1100007 | 100007@fixbug.com | 100007   |
| 1100008 | 100008@fixbug.com | 100008   |
| 1100009 | 100009@fixbug.com | 100009   |
| 1100010 | 100010@fixbug.com | 100010   |
| 1100011 | 100011@fixbug.com | 100011   |
| 1100012 | 100012@fixbug.com | 100012   |
| 1100013 | 100013@fixbug.com | 100013   |
| 1100014 | 100014@fixbug.com | 100014   |
| 1100015 | 100015@fixbug.com | 100015   |
| 1100016 | 100016@fixbug.com | 100016   |
| 1100017 | 100017@fixbug.com | 100017   |
| 1100018 | 100018@fixbug.com | 100018   |
| 1100019 | 100019@fixbug.com | 100019   |
| 1100020 | 100020@fixbug.com | 100020   |
+---------+-------------------+----------+
20 rows in set (0.00 sec)
```

#### 排序 order by

```shell
# 排序与多字段排序
mysql> select * from user order by name;
+----+----------+-----+-----+
| id | name     | age | sex |
+----+----------+-----+-----+
|  3 | chenwei  |  21 | M   |
|  2 | gaoyang  |  23 | M   |
|  4 | zhangfan |  22 | M   |
|  5 | zhanglan |  23 | W   |
|  6 | zhangsan |  21 | W   |
+----+----------+-----+-----+
5 rows in set (0.01 sec)

mysql> select * from user order by age, name;
+----+----------+-----+-----+
| id | name     | age | sex |
+----+----------+-----+-----+
|  3 | chenwei  |  21 | M   |
|  6 | zhangsan |  21 | W   |
|  4 | zhangfan |  22 | M   |
|  2 | gaoyang  |  23 | M   |
|  5 | zhanglan |  23 | W   |
+----+----------+-----+-----+
5 rows in set (0.00 sec)

```

外排序：

```shell
mysql> explain select * from user order by age\G
*************************** 1. row ***************************
           id: 1
  select_type: SIMPLE
        table: user
   partitions: NULL
         type: ALL
possible_keys: NULL
          key: NULL
      key_len: NULL
          ref: NULL
         rows: 4
     filtered: 100.00
        Extra: Using filesort	# 外排序，效率较低，涉及大量磁盘 IO
1 row in set, 1 warning (0.00 sec)
```

如何利用索引排序？

```shell
mysql> explain select * from user order by name\G	# 展示所有列的时候为外排序
*************************** 1. row ***************************
           id: 1
  select_type: SIMPLE
        table: user
   partitions: NULL
         type: ALL
possible_keys: NULL
          key: NULL
      key_len: NULL
          ref: NULL
         rows: 8
     filtered: 100.00
        Extra: Using filesort	# 外排序
1 row in set, 1 warning (0.00 sec)

mysql> explain select name from user order by name\G
# 仅展示有索引的元素时利用了索引
*************************** 1. row ***************************
           id: 1
  select_type: SIMPLE
        table: user
   partitions: NULL
         type: index
possible_keys: NULL
          key: name
      key_len: 152
          ref: NULL
         rows: 8
     filtered: 100.00
        Extra: Using index		# 利用索引
1 row in set, 1 warning (0.00 sec)

```

#### group by 分组操作

```shell
# 按年龄分组后列出
mysql> select age from user group by age;
+-----+
| age |
+-----+
|  23 |
|  21 |
|  22 |
|  18 |
|  52 |
|  34 |
+-----+
6 rows in set (0.00 sec)

# 效果相当于用 distinct
mysql> select distinct age from user;
+-----+
| age |
+-----+
|  23 |
|  21 |
|  22 |
|  18 |
|  52 |
|  34 |
+-----+
6 rows in set (0.00 sec)
```

**count()函数**：`select age count(age) as number from user grounp by age;`

**sum()函数**`select age sum(age) as number from user grounp by age`

也可列出多个分组

```shell
mysql> select age, sex, count(*) from user group by age, sex order by age;
# 将年龄和性别都相同的人分为一组
+-----+-----+----------+
| age | sex | count(*) |
+-----+-----+----------+
|  18 | M   |        1 |
|  21 | M   |        1 |
|  21 | W   |        1 |
|  22 | M   |        1 |
|  23 | M   |        1 |
|  23 | W   |        1 |
|  34 | M   |        1 |
|  52 | W   |        1 |
+-----+-----+----------+
8 rows in set (0.00 sec)
```

**性能**：

```shell
mysql> explain select age from user group by age\G
*************************** 1. row ***************************
           id: 1
  select_type: SIMPLE
        table: user
   partitions: NULL
         type: ALL
possible_keys: NULL
          key: NULL
      key_len: NULL
          ref: NULL
         rows: 9
     filtered: 100.00
        Extra: Using temporary	# 创建临时表（也使用了外排序，但未标出）
1 row in set, 1 warning (0.00 sec)

# 尝试分组有索引的元素
mysql> explain select name from user group by name\G
*************************** 1. row ***************************
           id: 1
  select_type: SIMPLE
        table: user
   partitions: NULL
         type: index
possible_keys: name
          key: name
      key_len: 152
          ref: NULL
         rows: 9
     filtered: 100.00
        Extra: Using index		# 使用了索引
1 row in set, 1 warning (0.00 sec)

```

#### 连接查询

连接以下两个查询：
`select uid, age, sex from student a where uid = 1;``
``select score from exame b where uid = 1 and cid = 2;`

```mysql
select
a.uid, a.name, a.age, a.sex, c.score
from
student a
join
exame c
where
a.uid = c.uid
order by
uid;
```

**也可以一次连接多张表**：

```mysql
select
a.uid, a.name, a.age, a.sex, b.cid, b.cname, b.credit, c.score
from
exame c
join
course b
on
b.cid = c.cid
join
studentt a
on
a.uid = c.uid;
```

*注意子句之间的顺序关系*

值得一提的是，在如下场景：

```shell
mysql> select b.cid, b.cname, b.credit, count(*) from course b join exame c on b.cid = c.cid group
-> by c.cid;	# 可以直接用 c.cid 分组而不是罗列出所有非聚合列

+-----+-----------------+--------+----------+
| cid | cname           | credit | count(*) |
+-----+-----------------+--------+----------+
|   1 | C++基础课程     |      5 |        2 |
|   2 | C++高级课程     |     10 |        4 |
|   3 | C++项目开发     |      8 |        3 |
|   4 | C++算法课程     |     12 |        3 |
+-----+-----------------+--------+----------+
4 rows in set (0.00 sec)

mysql> select b.cid, b.cname, b.credit, count(*) from course b join exame c on b.cid = c.cid group
-> by b.cid;	# 也可以直接用 b.cid

+-----+-----------------+--------+----------+
| cid | cname           | credit | count(*) |
+-----+-----------------+--------+----------+
|   1 | C++基础课程     |      5 |        2 |
|   2 | C++高级课程     |     10 |        4 |
|   3 | C++项目开发     |      8 |        3 |
|   4 | C++算法课程     |     12 |        3 |
+-----+-----------------+--------+----------+
4 rows in set (0.00 sec)

mysql> select b.cid, b.cname, b.credit, count(*) from course b join exame c on b.cid = c.cid group by b.cname;
ERROR 1055 (42000): Expression #1 of SELECT list is not in GROUP BY clause and contains nonaggregated column 'school.b.cid' which is not functionally dependent on columns in GROUP BY clause; this is incompatible with sql_mode=only_full_group_by

# 若使用 b.cname 则出现报错
```

出现这种情况的原因是，当你使用存在多个非聚合列的时候，你可以使用它们的主键（如果有）一次唯一标定它们，不是主键的元素或不能唯一标定时不能使用这种方法。

**`on a.uid = c.uid` 中区分大表和小表， 按照数量来区分，小表永远是整表扫描，然后去大表搜索**，因此建议在大表中建立索引。



**三种查询速度比较**

```shell
# 1. 直接查询整表
mysql> select * from t_user limit 1500000, 10;
+---------+--------------------+----------+
| id      | email              | password |
+---------+--------------------+----------+
| 2500001 | 1500001@fixbug.com | 1500001  |
| 2500002 | 1500002@fixbug.com | 1500002  |
| 2500003 | 1500003@fixbug.com | 1500003  |
| 2500004 | 1500004@fixbug.com | 1500004  |
| 2500005 | 1500005@fixbug.com | 1500005  |
| 2500006 | 1500006@fixbug.com | 1500006  |
| 2500007 | 1500007@fixbug.com | 1500007  |
| 2500008 | 1500008@fixbug.com | 1500008  |
| 2500009 | 1500009@fixbug.com | 1500009  |
| 2500010 | 1500010@fixbug.com | 1500010  |
+---------+--------------------+----------+
10 rows in set (0.27 sec)
# 2. 直接查询带索引列
mysql> select id from t_user limit 1500000, 10;
+---------+
| id      |
+---------+
| 2500001 |
| 2500002 |
| 2500003 |
| 2500004 |
| 2500005 |
| 2500006 |
| 2500007 |
| 2500008 |
| 2500009 |
| 2500010 |
+---------+
10 rows in set (0.08 sec)
# 3. 利用索引查询
mysql> select * from t_user where id > 2500000 limit 20;
+---------+--------------------+----------+
| id      | email              | password |
+---------+--------------------+----------+
| 2500001 | 1500001@fixbug.com | 1500001  |
| 2500002 | 1500002@fixbug.com | 1500002  |
| 2500003 | 1500003@fixbug.com | 1500003  |
| 2500004 | 1500004@fixbug.com | 1500004  |
| 2500005 | 1500005@fixbug.com | 1500005  |
| 2500006 | 1500006@fixbug.com | 1500006  |
| 2500007 | 1500007@fixbug.com | 1500007  |
| 2500008 | 1500008@fixbug.com | 1500008  |
| 2500009 | 1500009@fixbug.com | 1500009  |
| 2500010 | 1500010@fixbug.com | 1500010  |
| 2500011 | 1500011@fixbug.com | 1500011  |
| 2500012 | 1500012@fixbug.com | 1500012  |
| 2500013 | 1500013@fixbug.com | 1500013  |
| 2500014 | 1500014@fixbug.com | 1500014  |
| 2500015 | 1500015@fixbug.com | 1500015  |
| 2500016 | 1500016@fixbug.com | 1500016  |
| 2500017 | 1500017@fixbug.com | 1500017  |
| 2500018 | 1500018@fixbug.com | 1500018  |
| 2500019 | 1500019@fixbug.com | 1500019  |
| 2500020 | 1500020@fixbug.com | 1500020  |
+---------+--------------------+----------+
20 rows in set (0.00 sec)	# 最快
```

**还可以利用创建临时表的索引查询：**

```shell
mysql> select a.id, a.email, a.password from t_user a inner join (select id from t_user limit 1500000, 10) b on a.id = b.id;
+---------+--------------------+----------+
| id      | email              | password |
+---------+--------------------+----------+
| 2500001 | 1500001@fixbug.com | 1500001  |
| 2500002 | 1500002@fixbug.com | 1500002  |
| 2500003 | 1500003@fixbug.com | 1500003  |
| 2500004 | 1500004@fixbug.com | 1500004  |
| 2500005 | 1500005@fixbug.com | 1500005  |
| 2500006 | 1500006@fixbug.com | 1500006  |
| 2500007 | 1500007@fixbug.com | 1500007  |
| 2500008 | 1500008@fixbug.com | 1500008  |
| 2500009 | 1500009@fixbug.com | 1500009  |
| 2500010 | 1500010@fixbug.com | 1500010  |
+---------+--------------------+----------+
10 rows in set (0.08 sec)
# 与上文中直接查询索引列的速度相同的情况下查到了其他非索引列。

mysql> explain select * from t_user a inner join (select id from t_user limit 1500000, 1) b on a.id = b.id\G
*************************** 1. row ***************************
           id: 1
  select_type: PRIMARY
        table: <derived2>
   partitions: NULL
         type: ALL
possible_keys: NULL
          key: NULL
      key_len: NULL
          ref: NULL
         rows: 1500001
     filtered: 100.00
        Extra: NULL
*************************** 2. row ***************************
           id: 1
  select_type: PRIMARY
        table: a
   partitions: NULL
         type: eq_ref
possible_keys: PRIMARY
          key: PRIMARY
      key_len: 4
          ref: b.id
         rows: 1
     filtered: 100.00
        Extra: NULL
*************************** 3. row ***************************
           id: 2
  select_type: DERIVED
        table: t_user
   partitions: NULL
         type: index
possible_keys: NULL
          key: PRIMARY
      key_len: 4
          ref: NULL
         rows: 1995777
     filtered: 100.00
        Extra: Using index	# 查询时使用了索引
3 rows in set, 1 warning (0.00 sec)
```

> 上文提到：**`on a.uid = c.uid` 中区分大表和小表， 按照数量来区分，小表永远是整表扫描，然后去大表搜索**，因此建议在大表中建立索引。

注意：当内连接语句后加了 where 语句时，会先执行 where 限制条件后，再界定大小表。

示例：

```shell
mysql> explain select a.*, b.* from student a inner join exame b on a.uid = b.uid\G 
*************************** 1. row ***************************
           id: 1
  select_type: SIMPLE
        table: a
   partitions: NULL
         type: ALL
possible_keys: PRIMARY
          key: NULL		# 小表；整表查询
      key_len: NULL
          ref: NULL
         rows: 6
     filtered: 100.00
        Extra: NULL
*************************** 2. row ***************************
           id: 1
  select_type: SIMPLE
        table: b
   partitions: NULL
         type: ref
possible_keys: PRIMARY
          key: PRIMARY	# 大表；使用索引
      key_len: 4
          ref: school.a.uid
         rows: 2
     filtered: 100.00
        Extra: NULL
2 rows in set, 1 warning (0.00 sec)

# 添加一个 where 限制条件使原来的大表变小
mysql> explain select a.*, b.* from student a join exame b on a.uid = b.uid where b.uid = 3\G
*************************** 1. row ***************************
           id: 1
  select_type: SIMPLE
        table: a
   partitions: NULL
         type: const
possible_keys: PRIMARY
          key: PRIMARY	# 由小表变为大表。使用索引查询
      key_len: 4
          ref: const
         rows: 1
     filtered: 100.00
        Extra: NULL
*************************** 2. row ***************************
           id: 1
  select_type: SIMPLE
        table: b
   partitions: NULL
         type: ref
possible_keys: PRIMARY
          key: PRIMARY
      key_len: 4
          ref: const
         rows: 4
     filtered: 100.00
        Extra: NULL
2 rows in set, 1 warning (0.00 sec)

# 同时，对于 inner join 内连接，过滤条件写在 where 和 on 内的条件是一样的，是一种优化行为。
```

#### 外连接查询

##### 左连接

```shell
# 显示出左表的所有数据，若右表中不存在对应数据，显示为 NULL。
mysql> select a.*, b.* from student a left join exame b on a.uid = b.uid;
+-----+----------+-----+-----+------+------+------------+-------+
| uid | name     | age | sex | uid  | cid  | time       | score |
+-----+----------+-----+-----+------+------+------------+-------+
|   1 | zhangsan |  18 | M   |    1 |    1 | 2021-04-09 |    99 |
|   1 | zhangsan |  18 | M   |    1 |    2 | 2021-04-10 |    80 |
|   2 | gaoyang  |  20 | W   |    2 |    2 | 2021-04-10 |    90 |
|   2 | gaoyang  |  20 | W   |    2 |    3 | 2021-04-12 |    85 |
|   3 | chenwei  |  22 | M   |    3 |    1 | 2021-04-09 |    56 |
|   3 | chenwei  |  22 | M   |    3 |    2 | 2021-04-10 |    93 |
|   3 | chenwei  |  22 | M   |    3 |    3 | 2021-04-12 |    89 |
|   3 | chenwei  |  22 | M   |    3 |    4 | 2021-04-11 |   100 |
|   4 | linfeng  |  21 | W   |    4 |    4 | 2021-04-11 |    99 |
|   5 | liuxiang |  19 | W   |    5 |    2 | 2021-04-10 |    59 |
|   5 | liuxiang |  19 | W   |    5 |    3 | 2021-04-12 |    94 |
|   5 | liuxiang |  19 | W   |    5 |    4 | 2021-04-11 |    95 |
|   7 | weiwei   |  20 | W   | NULL | NULL | NULL       |  NULL |
+-----+----------+-----+-----+------+------+------------+-------+
13 rows in set (0.00 sec)
```

##### 右连接

同理。

由上图可以得出，如何筛选出未参加考试的同学？只需要找到左连接后  `b.cid is null` 的数据就可以了：
`select a.* from student a left join exame b on a.uid = b.uid where b.cid is null;`

当然，直接查找在 student 中但不在 exame 中的元素也可：
`select * from student where student.uid not in (select uid from exame);`

**注意**：在外连接时，判断条件写在 on 子句里和 where 子句里的作用截然不同，where 子句往往会在最后执行。
例如：找出没参加 uid = 3 的考试的人

```shell
# 正确写法
mysql> select a.*, b.* from student a left join exame b on a.uid = b.uid and b.cid = 3 where b.cid is null;
+-----+----------+-----+-----+------+------+------+-------+
| uid | name     | age | sex | uid  | cid  | time | score |
+-----+----------+-----+-----+------+------+------+-------+
|   1 | zhangsan |  18 | M   | NULL | NULL | NULL |  NULL |
|   4 | linfeng  |  21 | W   | NULL | NULL | NULL |  NULL |
|   7 | weiwei   |  20 | W   | NULL | NULL | NULL |  NULL |
+-----+----------+-----+-----+------+------+------+-------+
3 rows in set (0.01 sec)
```

## MySQL 索引

**索引分类：**

+ 物理上：聚集索引、非聚集索引

+ 逻辑上：

  + 普通索引：没有任何限制条件，可以给任何类型的字段设置。

    ps：一次的 SQL 查询只能用一次索引。

  + 唯一性索引：使用 UNIQUE 修饰的字段，值不能重复。

    ps：主键索引就属于唯一性索引。

  + 主键索引：使用 PRIMIARY KEY 修饰的字段会自动创建索引。

    ps：MyISAM 存储引擎在没有加主键的时候默认不添加主键索引，innoDB 没有添加主键会默认添加一个主键（底层结构）。

  + 单列索引：在一个字段上创建索引。

  + 多列索引：在表的多个字段上创建索引（例如联合主键）

  + 全文索引：用于数量较大的字符串类。

**添加索引：**

```shell
mysql> create index nameidx on student(name);
Query OK, 0 rows affected (0.05 sec)
Records: 0  Duplicates: 0  Warnings: 0

# 查看索引
mysql> show create table student\G
*************************** 1. row ***************************
       Table: student
Create Table: CREATE TABLE `student` (
  `uid` int unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(50) NOT NULL,
  `age` tinyint unsigned NOT NULL,
  `sex` enum('M','W') NOT NULL,
  PRIMARY KEY (`uid`),		# 主键索引
  KEY `nameidx` (`name`)	# 新添加的索引	
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
1 row in set (0.00 sec)

# 再次查询
mysql> explain select * from student where name = 'zhangsan'\G
*************************** 1. row ***************************
           id: 1
  select_type: SIMPLE
        table: student
   partitions: NULL
         type: ref
possible_keys: nameidx
          key: nameidx		# 使用索引
      key_len: 202
          ref: const
         rows: 1
     filtered: 100.00
        Extra: NULL
1 row in set, 1 warning (0.00 sec)
```

注意：

1. 经常作为 where 条件过滤的字段考虑添加索引。
2. 字符串列创建索引时，尽量规定索引的长度，而不能索引的长度 key_len 过长
3. 索引字段涉及类型强转、mysql 函数调用、表达式计算等，索引就用不上了。

### InnoDB 的主键和索引树 - B+  树索引

InnoDB 引擎的存储特点：数据和索引存储在一块。

#### 场景一：uid 是主键

`select * from student`：搜索整棵树（链表）
`select * from student where uid = 5`：等值查询（使用了索引）
`select * from student where uid < 5`：范围查询（没有使用索引）
`select * from student where name = 'linfeng'`

#### 场景二：uid 是主键，name 创建了普通索引（二级索引）

 例：对比以下几种查询得出结论。

```shell
# name 建立了普通索引（二级索引）
mysql> explain select uid, name from student where name = 'linfeng'\G
*************************** 1. row ***************************
           id: 1
  select_type: SIMPLE
        table: student
   partitions: NULL
         type: ref
possible_keys: nameidx
          key: nameidx
      key_len: 202
          ref: const
         rows: 1
     filtered: 100.00
        Extra: Using index	# 使用索引直接查询
1 row in set, 1 warning (0.00 sec)

mysql> explain select * from student where name = 'linfeng'\G
*************************** 1. row ***************************
           id: 1
  select_type: SIMPLE
        table: student
   partitions: NULL
         type: ref
possible_keys: nameidx
          key: nameidx
      key_len: 202
          ref: const
         rows: 1
     filtered: 100.00
        Extra: NULL			# 回表
1 row in set, 1 warning (0.00 sec)

mysql> explain select * from student where age = 20 order by name\G
*************************** 1. row ***************************
           id: 1
  select_type: SIMPLE
        table: student
   partitions: NULL
         type: ref
possible_keys: idx_age
          key: idx_age
      key_len: 1
          ref: const
         rows: 2
     filtered: 100.00
        Extra: Using filesort
1 row in set, 1 warning (0.00 sec)

# 上一个例子中只给 name 和 age 都有索引，也成功使用了 age 的索引应对等值查询
# 但是却调用了外排序：一次查询只能使用一个索引。

# 若要避免，创建联合索引。
mysql> explain select * from student where age = 20 order by name\G
*************************** 1. row ***************************
           id: 1
  select_type: SIMPLE
        table: student
   partitions: NULL
         type: ref
possible_keys: idx_age,idx_age_name
          key: idx_age_name
      key_len: 1
          ref: const
         rows: 2
     filtered: 100.00
        Extra: NULL			# 不再调用外排序
1 row in set, 1 warning (0.00 sec)
```

### MyISAM 的主键和索引树 - B+ 树索引

#### 场景：uid 是主键，name 是二级索引

非聚集索引，每个索引树都是一个独立的树。。。

### 哈希索引 ---  基于内存的存储引擎

由于哈希表的结构限制，哈希表中的元素顺序完全随机，只能进行等值比较

`select * from student where name = 'zhangsan';` <== 使用索引
`select * from student where name like 'zhang%';` <== 无法使用索引

同理：范围搜索，前缀搜索，order by 排序，哈希表都不适合。
哈希索引也无法处理磁盘上的数据。

#### InnoDB 自适应哈希索引

搜索引擎检测到同样的二级索引（回表）不断被使用，会根据这个二级索引树上的二级索引值在内存上构建一个哈希索引，实现加速搜索。
**注意：**自适应哈希索引本身的数据维护也要耗费性能，不能在任何情况下都能提升查询性能。根据参数指标具体分析打开或关闭自适应哈希索引。

### 慢查询日志

在事件中可能存在大量 sql 语句，无法逐一使用 explain 观察。

> MySQL 可以设置慢查询日志，当 SQL 执行的时间超过我们设定的时间，那么这些 SQL 就会被记录在慢查询日志当中，然后我们通过查看日志，用 explain 分析这些 SQL 的执行计划，来判定为什么效率低下，是没有使用到索引？还是索引本身创建的有问题？或者是索引使用到了，但是由于表的数据量太大，花费的时间就是很长，那么此时我们可以把表分成 n 个小表，比如订单表按年份分成多个小表等。

**慢查询日志设置**

```shell
mysql> show variables like 'slow_query%';
+---------------------+--------------------------------+
| Variable_name       | Value                          |
+---------------------+--------------------------------+
| slow_query_log      | OFF                            |
| slow_query_log_file | /var/lib/mysql/ubuntu-slow.log |
+---------------------+--------------------------------+
2 rows in set (0.00 sec)

mysql> set slow_query_log = ON;
ERROR 1229 (HY000): Variable 'slow_query_log' is a GLOBAL variable and should be set with SET GLOBAL
mysql> set global slow_query_log = ON;
Query OK, 0 rows affected (0.00 sec)

# 设置慢查询时间
mysql> show variables like 'long_query%';
+-----------------+-----------+
| Variable_name   | Value     |
+-----------------+-----------+
| long_query_time | 10.000000 |
+-----------------+-----------+
1 row in set (0.00 sec)

mysql> set long_query_time = 0.1;	# 单位为秒
Query OK, 0 rows affected (0.00 sec)

...	# 压测执行各种业务

# 在 mysql 目录下可以查找到慢查询文件
root@ubuntu:/var/lib/mysql\# ls ubuntu-slow.log 
ubuntu-slow.log
root@ubuntu:/var/lib/mysql\# cat ubuntu-slow.log 
/usr/sbin/mysqld, Version: 8.0.42-0ubuntu0.24.10.1 ((Ubuntu)). started with:
Tcp port: 3306  Unix socket: /var/run/mysqld/mysqld.sock
Time                 Id Command    Argument
# Time: 2025-06-07T10:14:36.933032Z
# User@Host: root[root] @ localhost []  Id:    11
# Query_time: 0.876773  Lock_time: 0.000004 Rows_sent: 1  Rows_examined: 2000000
use school;
SET timestamp=1749291276;
select * from t_user where password = 1520000;

```

## MySQL 事务

> 一个事务是由一条或者多条对数据库操作的SQL语句所组成的一个不可分割的单元，只有当事务中的所有操作都正常执行完了，整个事务才会被提交给数据库；如果有部分事务处理失败，那么事务就要回退到最初的状态，因此，事务要么全部执行成功，要么全部失败。 所以记住事务的几个基本概念，如下： 
>
> 1. 事务是**一组**SQL语句的执行，要么全部成功，要么全部失败，不能出现部分成功，部分失败的结果。保证事务执行的原子操作。
> 2. 事务的所有SQL语句**全部执行成功**，才能提交（commit）事务，把结果写回磁盘上。
> 3. 事务执行过程中，有的SQL出现错误，那么事务必须要**回滚**（rollback）到最初的状态。

### 事务的 ACID 特性：

ACD：是由 mysql 的 redo log 和 undo log 机制来保证的
I：独立性，是由 mysql 事务的锁机制来保证的

### 事务并发存在的问题 

事务处理不经隔离，并发执行事务时通常会发生以下的问题：

- **脏读（Dirty Read）**：一个事务读取了另一个事务未提交的数据。例如当事务A和事务B并发执行时，当事务A更新后，事务B查询读取到A尚未提交的数据，此时事务A回滚，则事务B读到的数据就是无效的脏数据。（事务B读取了事务A尚未提交的数据）
- **不可重复读（NonRepeatable Read）**：一个事务的操作导致另一个事务前后两次读取到不同的数据。例如当事务A和事务B并发执行时，当事务B查询读取数据后，事务A更新操作更改事务B查询到的数据，此时事务B再次去读该数据，发现前后两次读的数据不一样。（事务B读取了事务A已提交的数据）
- **虚读（Phantom Read）幻读**：一个事务的操作导致另一个事务前后两次查询的结果数据量不同。例如当事务A和事务B并发执行时，当事务B查询读取数据后，事务A新增或者删除了一条满足事务B查询条件的记录，此时事务B再去查询，发现查询到前一次不存在的记录，或者前一次查询的一些记录不见了。（事务B读取了事务A新增加的数据或者读不到事务A删除的数据）  

### 事务的隔离级别
MySQL支持的四种隔离级别是:  

1. TRANSACTION_READ_UNCOMMITTED。未提交读。说明在提交前一个事务可以看到另一个事务的变化。这样读脏数据，不可重复读和虚读都是被允许的。  
2. TRANSACTION_READ_COMMITTED。已提交读。说明读取未提交的数据是不允许的。这个级别仍然允许不可重复读和虚读产生。  
3. TRANSACTION_REPEATABLE_READ。可重复读。说明事务保证能够再次读取相同的数据而不会失败，但虚读仍然会出现。  
4. TRANSACTION_SERIALIZABLE。串行化。是最高的事务级别，它防止读脏数据，不可重复读和虚读。  


| 隔离级别       | 脏读   | 不可重复读 | 幻读   |  
| -------------- | ------ | ---------- | ------ |  
| 未提交读       | 可以   | 可以       | 可以   |  
| 已提交读       | 不可以 | 可以       | 可以   |  
| 可重复读       | 不可以 | 不可以     | 可以   |  
| 串行化         | 不可以 | 不可以     | 不可以 |  

备注:  
事务隔离级别越高，为避免冲突所花费的性能也就越多。  
在“可重复读”级别，实际上可以解决部分的虚读问题（由 `insert` 和 `delete`导致的幻读），但是不能防止update更新产生的虚读问题，要禁止虚读产生，还是需要设置串行化隔离级别。  

举例：

```shell
# 设置事务隔离等级为 未提交读，演示读取脏数据。
mysql> set global transaction_isolation = 'READ-UNCOMMITTED';
Query OK, 0 rows affected (0.00 sec)

mysql> select @@transaction_isolation;
+-------------------------+
| @@transaction_isolation |
+-------------------------+
| READ-UNCOMMITTED        |
+-------------------------+
1 row in set (0.00 sec)

mysql> begin;
Query OK, 0 rows affected (0.00 sec)

mysql> update user set name = 'libai' where id = 10;
Query OK, 1 row affected (0.00 sec)
Rows matched: 1  Changed: 1  Warnings: 0

# 制造脏数据
mysql> select * from user;
+----+----------+-----+-----+
| id | name     | age | sex |
+----+----------+-----+-----+
|  2 | gaoyang  |  23 | M   |
|  3 | chenwei  |  21 | M   |
|  4 | zhangfan |  22 | M   |
|  5 | zhanglan |  23 | W   |
|  6 | zhangsan |  21 | W   |
|  7 | lisi     |  18 | M   |
|  8 | wangwu   |  52 | W   |
|  9 | zhaoliu  |  34 | M   |
| 10 | libai    |  18 | M   |
+----+----------+-----+-----+
9 rows in set (0.00 sec)

mysql> rollback;	# 回滚，使得上述的修改失效。
Query OK, 0 rows affected (0.00 sec)

```

```shell
# 开启新连接，尝试读取脏数据
mysql> begin;
Query OK, 0 rows affected (0.00 sec)

mysql> select * from user where id = 10;
+----+----------+-----+-----+
| id | name     | age | sex |
+----+----------+-----+-----+
| 10 | libai    |  18 | M   |
+----+----------+-----+-----+
9 rows in set (0.00 sec)

# 此时刚刚的修改被回滚

mysql> select * from user where id = 10;
+----+----------+-----+-----+
| id | name     | age | sex |
+----+----------+-----+-----+
| 10 | dufu     |  18 | M   |
+----+----------+-----+-----+
9 rows in set (0.00 sec)

mysql> rollback;
Query OK, 0 rows affected (0.00 sec)
```

> tips：在旧版本，只需在一个客户端执行 `set transaction_isolation = 'READ-UNCOMMITTED'` 即可同步完成对于所有客户端的修改。新版本以后，一个客户端只能修改所在客户端的隔离级别，若使用 `set global transaction_isolation = 'READ-UNCOMMITTED'` 也仅仅只能对以后打开的新客户端起作用。要想复现示例，需要保证两个事务所在的客户端都开启了 READ-UNCOMMITTED，否则会自动选择较高的隔离等级。

## MySQL 锁机制

### 表级锁&行级锁  
- **表级锁**：对整张表加锁。开销小，加锁快，不会出现死锁；锁粒度大，发生锁冲突的概率高，并发度低。  
- **行级锁**：对某行记录加锁。开销大，加锁慢，会出现死锁；锁定粒度最小，发生锁冲突的概率最低，并发度高。  


### 排它锁和共享锁  
- **排它锁（Exclusive）**：又称为X锁，写锁。  
- **共享锁（Shared）**：又称为S锁，读锁。  


X和S锁之间有以下的关系： SS可以兼容的，SX、XX、XS之间是互斥的  
- 一个事务对数据对象 O 加了 S 锁，可以对 O 进行读取操作但不能进行更新操作。加锁期间其它事务能对O 加 S 锁但不能加 X 锁。  
- 一个事务对数据对象 O 加了 X 锁，就可以对 O 进行读取和更新。加锁期间其它事务不能对 O 加任何锁。  
- 显示加锁：`select ... lock in share mode`强制获取共享锁，`select ... for update`获取排它锁  

### InnoDB行级锁  

InnoDB存储引擎支持事务处理，表支持行级锁定，并发能力更好。  

1. InnoDB行锁是通过给索引上的索引项加锁来实现的，而不是给表的行记录加锁实现的，这就意味着只有通过索引条件检索数据，InnoDB才使用行级锁，否则InnoDB将使用表锁。  
```shell
# 示例
# shell 1 中给一个没有索引的行加锁：
mysql> begin;
Query OK, 0 rows affected (0.00 sec)

mysql> select * from user where name = 'zhangsan' for update;
+----+----------+-----+-----+
| id | name     | age | sex |
+----+----------+-----+-----+
|  6 | zhangsan |  21 | W   |
+----+----------+-----+-----+
1 row in set (0.01 sec)

# 在 shell 2 中尝试访问该表
mysql> begin;
Query OK, 0 rows affected (0.00 sec)

mysql> select * from user where name = 'zhangsan' for update;
^C^C -- query aborted
ERROR 1317 (70100): Query execution was interrupted
mysql> select * from user where name = 'chenwei' for update;
^C^C -- query aborted
ERROR 1317 (70100): Query execution was interrupted
mysql> select * from user where id = 6 for update;
^C^C -- query aborted
ERROR 1317 (70100): Query execution was interrupted
mysql> select * from user where id = 7 for update;
^C^C -- query aborted
ERROR 1317 (70100): Query execution was interrupted
# 可见：针对过滤条件没有索引的情况，InnoDB 使用了表锁。
```
2. 由于InnoDB的行锁实现是针对索引字段添加的锁，不是针对行记录加的锁，因此虽然访问的是InnoDB引擎下表的不同行，但是如果使用相同的索引字段作为过滤条件，依然会发生锁冲突，只能串行进行，不能并发进行。  
3. 即使SQL中使用了索引，但是经过MySQL的优化器后，如果认为全表扫描比使用索引效率更高，此时会放弃使用索引，因此也不会使用行锁，而是使用表锁，比如对一些很小的表，MySQL就不会去使用索引。  

*值得注意的是，行锁看起来就是绑定了一整个行，锁的是主键索引树，所以给有二级索引的元素加锁，访问的时候用主键过滤条件，也是会阻塞的：*

```shell
# shell 1：
mysql> begin;
Query OK, 0 rows affected (0.00 sec)

mysql> select * from user where name = 'zhangsan' for update;
+----+----------+-----+-----+
| id | name     | age | sex |
+----+----------+-----+-----+
|  6 | zhangsan |  21 | W   |
+----+----------+-----+-----+
1 row in set (0.00 sec)
# shell 2：
mysql> begin;
Query OK, 0 rows affected (0.00 sec)

mysql> select * from user where name = 'zhangsan' for update;
^C^C -- query aborted
ERROR 1317 (70100): Query execution was interrupted			# 被锁
mysql> select * from user where name = 'lisi' for update;
+----+------+-----+-----+
| id | name | age | sex |
+----+------+-----+-----+
|  7 | lisi |  18 | M   |
+----+------+-----+-----+
1 row in set (0.00 sec)

mysql> select * from user where id = 6 for update;
^C^C -- query aborted
ERROR 1317 (70100): Query execution was interrupted			# 依旧被锁
```

### 间隙锁

串行化如何解决幻读问题？
每次请求共享或排它锁的时候，串行化不仅给满足范围内的索引项加锁，对于属于范围内但不存在的元素，也会给这个“间隙”加锁，这种锁机制就叫做间隙锁。
注意：间隙锁会给范围之外的最近的一个间隙加锁，所以插入数据时要注意是不是会落到这个间隙中。

### MVCC多版本并发控制

> MVCC是多版本并发控制（Multi-Version Concurrency Control，简称MVCC），是MySQL中基于乐观锁理论实现隔离级别的方式，用于实现已提交读和可重复读隔离级别的实现，也经常称为多版本数据库。MVCC机制会生成一个数据请求时间点的一致性数据快照（Snapshot），并用这个快照来提供一定级别（语句级或事务级）的一致性读取。从用户的角度来看，好象是数据库可以提供同一数据的多个版本（系统版本号和事务版本号）。
>

#### MVCC多版本并发控制中，读操作可以分为两类：
1. 快照读（snapshot read）
读的是记录的可见版本，不用加锁。如`select` 

2. 当前读（current read）
读取的是记录的最新版本，并且当前读返回的记录。如`insert`，`delete`，`update`，`select...lock in share mode/for update` 


MVCC：每一行记录实际上有多个版本，每个版本的记录除了数据本身之外，增加了其它字段 
- `DB_TRX_ID`：记录当前事务ID 
- `DB_ROLL_PTR`：指向undo log日志上数据的指针 


- **已提交读**：**每次执行语句的时候**都重新生成一次快照（Read View）。 
- **可重复读**：同一个事务**开始的时候**生成一个当前事务全局性的快照（Read View）。


#### 快照内容读取原则：
1. 版本未提交无法读取生成快照
2. 版本已提交，但是在快照创建后提交的，无法读取 
3. 版本已提交，但是在快照创建前提交的，可以读取 
4. 当前事务内自己的更新，**可以读到**  

### 意向共享锁和意向排他锁

- **意向共享锁（IS 锁）**：事务计划给记录加行共享锁，事务在给一行记录加共享锁前，必须先取得该表的 IS 锁。  

- **意向排他锁（IX 锁）**：事务计划给记录加行排他锁，事务在给一行记录加排他锁前，必须先取得该表的 IX 锁。  


|      | X        | IX       | S        | IS       |
| ---- | -------- | -------- | -------- | -------- |
| X    | Conflict | Conflict | Conflict | Conflict |
| IX   | Conflict | 兼容     | Conflict | 兼容     |
| S    | Conflict | Conflict | 兼容     | 兼容     |
| IS   | Conflict | 兼容     | 兼容     | 兼容     |  


1. 意向锁是由 InnoDB 存储引擎获取行锁之前自己获取的  
2. 意向锁之间都是兼容的，不会产生冲突  
3. 意向锁存在的意义是为了更高效的获取表锁（表格中的 X 和 S 指的是表锁，不是行锁！！！ ）  
4. 意向锁是表级锁，协调表锁和行锁的共存关系。主要目的是显示事务正在锁定某行或试图锁定某行。  