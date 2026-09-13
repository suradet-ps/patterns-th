# RAII พร้อมการ์ด (guards)

## คำอธิบาย

[RAII][wikipedia] ย่อมาจาก "Resource Acquisition is Initialisation" ซึ่งเป็นชื่อที่แย่มาก สาระสำคัญของแพตเทิร์นคือการเริ่มต้นทรัพยากรทำในคอนสตรัคเตอร์ของออบเจกต์ และการสิ้นสุด (finalisation) ทำในเดสทรัคเตอร์ แพตเทิร์นนี้ถูกขยายใน Rust โดยใช้ออบเจกต์ RAII เป็นการ์ดของทรัพยากรบางอย่าง และพึ่งพาระบบชนิดเพื่อรับประกันว่าการเข้าถึงจะถูกส่งผ่านการ์ดนั้นเสมอ

## ตัวอย่าง

การ์ดของ Mutex เป็นตัวอย่างคลาสสิกของแพตเทิร์นนี้จากไลบรารีมาตรฐาน (นี่คือเวอร์ชันอย่างย่อของการอิมพลีเมนต์จริง):

```rust,ignore
use std::ops::Deref;

struct Foo {}

struct Mutex<T> {
    // We keep a reference to our data: T here.
    //..
}

struct MutexGuard<'a, T: 'a> {
    data: &'a T,
    //..
}

// Locking the mutex is explicit.
impl<T> Mutex<T> {
    fn lock(&self) -> MutexGuard<T> {
        // Lock the underlying OS mutex.
        //..

        // MutexGuard keeps a reference to self
        MutexGuard {
            data: self,
            //..
        }
    }
}

// Destructor for unlocking the mutex.
impl<'a, T> Drop for MutexGuard<'a, T> {
    fn drop(&mut self) {
        // Unlock the underlying OS mutex.
        //..
    }
}

// Implementing Deref means we can treat MutexGuard like a pointer to T.
impl<'a, T> Deref for MutexGuard<'a, T> {
    type Target = T;

    fn deref(&self) -> &T {
        self.data
    }
}

fn baz(x: Mutex<Foo>) {
    let xx = x.lock();
    xx.foo(); // foo is a method on Foo.
              // The borrow checker ensures we can't store a reference to the underlying
              // Foo which will outlive the guard xx.

    // x is unlocked when we exit this function and xx's destructor is executed.
}
```

## แรงจูงใจ

เมื่อทรัพยากรต้องถูกสิ้นสุดหลังการใช้งาน RAII ช่วยทำการสิ้นสุดนั้นได้ หากการเข้าถึงทรัพยากรนั้นหลังการสิ้นสุดถือเป็นข้อผิดพลาด แพตเทิร์นนี้ก็ช่วยป้องกันข้อผิดพลาดดังกล่าวได้

## ข้อดี

ป้องกันข้อผิดพลาดทั้งกรณีที่ทรัพยากรไม่ถูกสิ้นสุด และกรณีที่ทรัพยากรถูกใช้หลังการสิ้นสุด

## การอภิปราย

RAII เป็นแพตเทิร์นที่มีประโยชน์สำหรับรับประกันว่าทรัพยากรถูกคืนหน่วยความจำหรือสิ้นสุดอย่างถูกต้อง เราสามารถใช้ borrow checker ของ Rust เพื่อป้องกันข้อผิดพลาดที่เกิดจากการใช้ทรัพยากรหลังการสิ้นสุดได้ตั้งแต่ตอนคอมไพล์

เป้าหมายหลักของ borrow checker คือรับประกันว่าการอ้างอิงถึงข้อมูลจะไม่อายุยืนกว่าข้อมูลนั้น แพตเทิร์นการ์ด RAII ทำงานได้เพราะออบเจกต์การ์ดบรรจุการอ้างอิงถึงทรัพยากรข้างใต้และเปิดเผยเฉพาะการอ้างอิงเช่นนั้น Rust รับประกันว่าการ์ดจะอายุยืนกว่าทรัพยากรข้างใต้ไม่ได้ และการอ้างอิงถึงทรัพยากรที่ผ่านการ์ดจะอายุยืนกว่าการ์ดไม่ได้ หากต้องการเห็นว่ามันทำงานอย่างไร การพิจารณาลายเซ็นของ `deref` โดยไม่ตัดทอนไลฟ์ไทม์ (lifetime elision) จะช่วยได้:

```rust,ignore
fn deref<'a>(&'a self) -> &'a T {
    //..
}
```

เรฟเฟอเรนซ์ที่คืนกลับมาซึ่งชี้ไปยังทรัพยากรมีอายุการใช้งานเดียวกับ `self` (`'a`) borrow checker จึงรับประกันว่าอายุของเรฟเฟอเรนซ์ที่ชี้ไปยัง `T` จะสั้นกว่าอายุของ `self`

พึงสังเกตว่าการอิมพลีเมนต์ `Deref` ไม่ใช่ส่วนหลักของแพตเทิร์นนี้ มันเพียงทำให้การใช้งานออบเจกต์การ์ดสะดวกขึ้นเท่านั้น การอิมพลีเมนต์เมท็อด `get` บนการ์ดก็ได้ผลดีเช่นกัน

## ดูเพิ่มเติม

[สำนวนการทำขั้นสุดท้ายในเดสทรัคเตอร์](../../idioms/dtor-finally.md)

RAII เป็นแพตเทิร์นที่พบบ่อยใน C++:
[cppreference.com](http://en.cppreference.com/w/cpp/language/raii),
[wikipedia][wikipedia]

[wikipedia]: https://en.wikipedia.org/wiki/Resource_Acquisition_Is_Initialization

[Style guide entry](https://doc.rust-lang.org/1.0.0/style/ownership/raii.html)
(ปัจจุบันเป็นเพียงที่วางไว้เฉยๆ)
