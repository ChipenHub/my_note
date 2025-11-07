# Redis 相关命令以及原理

## Redis类型

### key 类型

本质上是字符串，可以存储任意二进制内容。长度上限为 512 MB
列出所有的 key：`keys *

删除`key`：`del key`



### value 类型

自增自减：`incr key`、`incrby key n`、`decr key`、`decrby key n`
查看存储类型：`object encoding key`

**`string`（字符串）：**字符串类型；可以是文本或二进制数据。

插入：`set user chipen`
读取：`get user`
自增：`incr counter`
仅在 `key`不存在时设置：`setnx counter 100`
设置一个`bitstr`且偏移位置为`a`，值为`b`：`setbit str a b`
读取一个`bitstr`的`c`位置的值：`get bit c`

所有的 value 底层字符串类型统一使用 SDS（Simple Dynamic String），对于小整数，redis 会进行优化，使用 int 类型。

```shell
127.0.0.1:6379> set test 11
OK
127.0.0.1:6379> object encoding test
"int"
127.0.0.1:6379> set test 111abc
OK
127.0.0.1:6379> object encoding test
"embstr"	# 柔性数组
```

使用柔性数组：只需要一次`malloc`和`free`。
#### 存储结构

- 字符串长度小于等于 20 且能转成整数，则使用 `int` 存储；  
- 字符串长度小于等于 44，则使用 `embstr` 存储；  
- 字符串长度大于 44，则使用 `raw` 存储；  

**`list`（链表）：**双端链表；可以从左 / 右插入或弹出。

插入：`lpush users user1 user2 user3 user4`
读取：`lrange users`
左弹出：`lpop list1`

**`set`（无序集合）**：不允许重复元素；底层是哈希表

插入：`sadd set1 chipen libai dufu wangzhihuan wangchangling`
返回集合元素个数：`scard key`
读取：`smembers set1`
判断是否存在：`sismember set1 chipen`
随机返回一个元素：`srandmember key [count]`
随机弹出一个元素：`spop key [count]`

**`hash`（哈希表）：**键值对的集合。

插入：`hset user:1001 name chipen`
读取：`hget user:1001 name`
读取所有键值对：`hgetall user:1001`

**`zset`（有序集合）：**每个元素都有一个分数（score）；自动排序。

插入：`zadd rank 100 chipen 200 libai 300 dufu`
读取：`zrange 0 -1 withscores`