# C++基础问题

## 掌握形参默认带缺省值的函数

函数调用时

```c++
#include <iostream>

int sum(int a, int b = 20) {
    return a + b;
}

int main() {
    int a = 10, b = 20;
    
    int ret = sum(a, b);
    cout << "ret: " << ret << endl;
    
    ret = sum(a);
    /*
    a 使用默认值
    压栈: 时压入 a 的值和 20.
    push 14H
    mov ecx, dowrd ptr[ebp - 4]
    push ecx
    call sum
    */
    ret = sum();
    // 压入 10 和 20.
}
```

总的来说，函数效率有所增长：减少一次 push 指令。

### 带有缺省的函数的声明

```cpp
// 一个缺省只能被声明一次，并且只能被从右向左声明
#if 1	// 编译通过
int sum(int a = 10, int b = 20);
#elif	// 报错: 默认值只能给一次
int sum(int a = 10, int b = 20);
int sum(int a, int b = 20);
#elif	// 编译通过
int sum(int a, int b = 20);
int sum(int a = 10, int b);
#endif

int main() {
    int a = 10, b = 20;
    
    int ret = sum(a, b);
    cout << "ret: " << ret << endl;
    
    ret = sum(a);
    /*
    a 使用默认值
    压栈: 时压入 a 的值和 20.
    push 14H
    mov ecx, dowrd ptr[ebp - 4]
    push ecx
    call sum
    */
    ret = sum();
    // 压入 10 和 20.
}

int sum(int a, int b) {
    return a + b;
}
```

## 掌握内联函数


内联函数和普通函数的区别?

+ 内联函数：在编译过程中没有函数调用的开销，因为在函数的调用点函数被直接展开处理。
+ 内联函数将不再产生相应的函数符号。
+ 函数定义时加上`inline`并不一定会让函数变成内联函数，仅仅是对编译器的一种建议。如递归很可能不会被处理为内联函数。

```cpp
#include <iostream>

using namespace std;

#define IS_INLINE   1

#if IS_INLINE
inline 
#endif

int sum(int a, int b = 20) {
    return a + b;
}

int main() {
    int a = 10, b = 20;
    
    int ret = sum(a, b);
    // 此处有标准的函数调用过程
	// 当函数调用的开销的占比过高，建议使用内联函数
    cout << "ret: " << ret << endl;


}
```

注意：`inline` 在 debug 版本上是不起作用的。

验证：`inline` 在 release 版能出现

```shell
chipen@ubuntu:~/code/inlineTest$ cat main.cpp
#include <iostream>

using namespace std;

int sum(int a, int b) {
	return a + b;

}

int main() {

	int a = 10, b = 20;

	int ret = sum(a, b);

	return 0;
	
}
chipen@ubuntu:~/code/inlineTest$ g++ -c main.cpp -O2
chipen@ubuntu:~/code/inlineTest$ objdump -t main.o

main.o:     file format elf64-x86-64

SYMBOL TABLE:
0000000000000000 l    df *ABS*	0000000000000000 main.cpp
0000000000000000 l    d  .text	0000000000000000 .text
0000000000000000 l    d  .text.startup	0000000000000000 .text.startup
0000000000000000         *UND*	0000000000000000 _ZSt21ios_base_library_initv
0000000000000000 g     F .text	0000000000000008 _Z3sumii	# sum 函数的符号
0000000000000000 g     F .text.startup	0000000000000007 main


chipen@ubuntu:~/code/inlineTest$ vim main.cpp	# 给 sum 函数加上 inline
chipen@ubuntu:~/code/inlineTest$ g++ -c main.cpp -O2
chipen@ubuntu:~/code/inlineTest$ objdump -t main.o

main.o:     file format elf64-x86-64

SYMBOL TABLE:
0000000000000000 l    df *ABS*	0000000000000000 main.cpp
0000000000000000 l    d  .text.startup	0000000000000000 .text.startup
0000000000000000         *UND*	0000000000000000 _ZSt21ios_base_library_initv
0000000000000000 g     F .text.startup	0000000000000007 main
# 可见，添加内联以后，sum 函数不再有对应的符号，而是被直接替换
chipen@ubuntu:~/code/inlineTest$ g++ -c main.cpp -O0
chipen@ubuntu:~/code/inlineTest$ objdump -t main.o

main.o:     file format elf64-x86-64

SYMBOL TABLE:
0000000000000000 l    df *ABS*	0000000000000000 main.cpp
0000000000000000 l    d  .text	0000000000000000 .text
0000000000000000 l    d  .text._Z3sumii	0000000000000000 .text._Z3sumii
0000000000000000 l     O .rodata	0000000000000001 _ZNSt8__detail30__integer_to_chars_is_unsignedIjEE
0000000000000001 l     O .rodata	0000000000000001 _ZNSt8__detail30__integer_to_chars_is_unsignedImEE
0000000000000002 l     O .rodata	0000000000000001 _ZNSt8__detail30__integer_to_chars_is_unsignedIyEE
0000000000000000         *UND*	0000000000000000 _ZSt21ios_base_library_initv
0000000000000000  w    F .text._Z3sumii	0000000000000018 _Z3sumii
0000000000000000 g     F .text	0000000000000033 main
# 在只用 -O0 的低优化等级时，inline 需求依然被忽略，可见 inline 只是一种建议行为
```

## 函数重载


```shell
chipen@ubuntu:~/code/inlineTest$ cat test01.cpp 
#include <iostream>
#include <cstring>

using namespace std;

bool compare(int a, int b) {
	cout << "int, int" << endl;
	return a > b;
}

bool compare(double a, double b) {
	cout << "double, double" << endl;
	return a > b;
}

bool compare(const char *a, const char *b) {
	cout << "const char*, const char*" << endl;
	return strcmp(a, b) > 0;
} 


int main() {
	compare(10, 20);
	compare(10.0, 20.0);
	compare("hello", "world");
	return 0;
}
chipen@ubuntu:~/code/inlineTest$ ./test01 
int, int
double, double
const char*, const char*
```

注意1: 一组重载函数指的是: 在同一作用域下的, 函数名相同作用域不同的函数

如当尝试在 main 函数中添加如下声明

```shell
chipen@ubuntu:~/code/inlineTest$ cat test01.cpp 
#include <iostream>
#include <cstring>

using namespace std;

bool compare(int a, int b) {
	cout << "int, int" << endl;
	return a > b;
}

bool compare(double a, double b) {
	cout << "double, double" << endl;
	return a > b;
}

bool compare(const char *a, const char *b) {
	cout << "const char*, const char*" << endl;
	return strcmp(a, b) > 0;
} 


int main() {
	bool compare(int a, int b);
	compare(10, 20);
	compare(10.0, 20.0);
	compare("hello", "world");
	return 0;
}
chipen@ubuntu:~/code/inlineTest$ g++ test01.cpp -o test01
test01.cpp: In function ‘int main()’:
test01.cpp:26:17: error: invalid conversion from ‘const char*’ to ‘int’ [-fpermissive]
   26 |         compare("hello", "world");
      |                 ^~~~~~~
      |                 |
      |                 const char*
test01.cpp:23:26: note:   initializing argument 1 of ‘bool compare(int, int)’
   23 |         bool compare(int a, int b);
      |                      ~~~~^
test01.cpp:26:26: error: invalid conversion from ‘const char*’ to ‘int’ [-fpermissive]
   26 |         compare("hello", "world");
      |                          ^~~~~~~
      |                          |
      |                          const char*
test01.cpp:23:33: note:   initializing argument 2 of ‘bool compare(int, int)’
   23 |         bool compare(int a, int b);
      |                             ~~~~^

```

注意2：同一类型，加不加`const`在编译器眼中没有区别。

```cpp
void func(int a) {}
void func(const int a) {}
// 报错

void func(int *a) {}
void func(const int *a) {}
// 编译通过

void func(int *a) {}
void func(int const *a) {}
// 报错
```



### 为什么 C++ 支持函数重载，C 语言不支持函数重载？

在对符号表中函数命名时，C++采取了更能准确描述一个函数的命名方式，而 C 语言直接用函数名字作为符号名。

因此，C 和 C++ 中的函数由于函数名不同，不能直接调用，会在链接时发生无法解析的外部符号的错误，因为在符号表中找不到对应的函数符号名。

要实现 C 和 C++ 之间都可以调用的函数，应该这样定义

```cpp
#ifdef __cplusplus
extern "C" {
#endif
int sum(int a, int b) {
    return a + b;
}
#ifdef __cplusplus
}
#endif
```

## 掌握`const`的用法

基本理解：`const` 修饰的**常变量**不能作为左值使用。
常变量 != 常量，例如：

```shell
chipen@ubuntu:~/code/inlineTest$ cat test02.cpp 
#include <cstdio>

int main() {
	const int a = 20;

	int *p = (int *)&a;

	*p = 30;
	printf("%d %d %d\n", a, *p, *(&a));
	return 0;		
}
chipen@ubuntu:~/code/inlineTest$ ./test02
20 30 30
```

这是个不可思议的现象。原因是：在编译器的前端阶段，a 被认为是不可能被修改的，故在后文中被做了直接替换，但是 `*p, *(&a)` 要求必须访问内存，故得到了 20 30 30。

证明这是一种优化行为：

```shell
chipen@ubuntu:~/code/inlineTest$ cat test02.cpp 
#include <cstdio>

int main() {
	volatile const int a = 20;	# 不让编译器优化 a

	int *p = (int *)&a;


	*p = 30;
	printf("%d %d %d\n", a, *p, *(&a));
	return 0;		
}
chipen@ubuntu:~/code/inlineTest$ ./test02
30 30 30	# 符合预期
```

`const`修饰的量常出现的错误是：

+ 常量不能再作为左值 <= 直接修改常量的值
+ 不能把常量的地址泄露给一个普通的指针或者普通的引用变量 <= 可能间接修改常量的值

`const`和一级指针的结合：（`const`修饰的是离它最近的类型）

+ `const int * p` -> 指针指向的变量不能修改
+ `int const * p` -> 同上
+ `int *const p` -> 指针本身不能修改
+ `const int *const p` -> 指针本身和指针所指的变量都不能修改

```cpp
int a = 10;			
int *p1 = &a;			// 通过, 无类型转换
const int *p2 = &a;		// 隐式类型转换
int *const p3 = &a;		// 隐式类型转换
const int b = 10;
int *p4 = &b;			// 不通过, (const int *) -> (int *)
const int *p5 = &b;		// 通过
int *const p6 = &b;		// 不通过, (const int *) -> (int *const)

// 总结: 权限只能缩小不能扩大
```

