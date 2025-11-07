类内定义的static变量在实现时不能带有static

class A {

    static int x;

};

is different with

static int A::x;

类内定义的const变量实现时必须带有const

何时include “class.h” 何时直接声明类：直接声明类编译器不知道具体的成员变量和成员方法。

 error: no matching function for call to ‘Poller::Poller()’
