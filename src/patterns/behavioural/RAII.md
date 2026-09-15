# RAII พร้อมการ์ด (RAII with guards)

## คำอธิบาย

[RAII][wikipedia] ย่อมาจาก "Resource Acquisition Is Initialization" ซึ่งถือเป็นชื่อที่ชวนสับสนไม่น้อย แต่สาระสำคัญที่แท้จริงของแพตเทิร์นนี้คือ "การจัดสรรและเตรียมทรัพยากรให้พร้อมในขั้นตอนการสร้างออบเจกต์ (constructor) และทำการคืนหรือปิดทรัพยากร (finalisation / cleanup) ในขั้นตอนการทำลายออบเจกต์ (destructor)" สำหรับในภาษา Rust แพตเทิร์นนี้ได้รับการต่อยอดโดยนำออบเจกต์ RAII มาทำหน้าที่เป็น "การ์ด" (guard) คอยคุ้มครองทรัพยากร และอาศัยระบบชนิดข้อมูล (type system) เพื่อรับประกันว่าการเข้าถึงทรัพยากรจะต้องกระทำผ่านออบเจกต์การ์ดนี้เสมอ

## ตัวอย่าง

Mutex Guard ในไลบรารีมาตรฐานถือเป็นตัวอย่างคลาสสิกของแพตเทิร์นนี้ (โค้ดด้านล่างนี้เป็นเวอร์ชันอย่างย่อของการอิมพลีเมนต์จริง):

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

ในกรณีที่ทรัพยากรต้องได้รับการปิดหรือคืนหน่วยความจำอย่างถูกต้องหลังการใช้งาน เราสามารถนำ RAII มาช่วยรับผิดชอบกระบวนการนี้ได้โดยอัตโนมัติ และหากการเข้าถึงทรัพยากรหลังจากถูกปิดไปแล้วถือเป็นข้อผิดพลาดร้ายแรง แพตเทิร์นนี้จะช่วยป้องกันไม่ให้เกิดความผิดพลาดดังกล่าวได้อย่างสิ้นเชิง

## ข้อดี

ช่วยป้องกันทั้งข้อผิดพลาดจากการลืมคืนทรัพยากร และข้อผิดพลาดจากการเผลอนำทรัพยากรที่ถูกคืนไปแล้วกลับมาใช้งานซ้ำ (use-after-free)

## การอภิปราย

RAII เป็นแพตเทิร์นที่มีประโยชน์อย่างยิ่งในการรับประกันว่าทรัพยากรจะถูกคืนหน่วยความจำหรือปิดการทำงานอย่างถูกต้องปลอดภัยเสมอ ในภาษา Rust เราสามารถใช้ประโยชน์จาก borrow checker เพื่อป้องกันข้อผิดพลาดจากการเข้าถึงทรัพยากรหลังถูกปิดได้ตั้งแต่ขั้นตอนการคอมไพล์

เป้าหมายหลักของ borrow checker คือการรับประกันว่าการอ้างอิง (reference) ไปยังข้อมูลจะต้องไม่คงอยู่ยาวนานกว่าตัวข้อมูลนั้น (do not outlive) แพตเทิร์น RAII Guard ทำงานได้อย่างมีประสิทธิภาพเนื่องจากตัวออบเจกต์การ์ดจะเก็บการอ้างอิงไปยังทรัพยากรเบื้องหลัง และเปิดให้เข้าถึงข้อมูลได้ผ่านการอ้างอิงนี้เท่านั้น โดย Rust จะรับประกันว่าตัวการ์ดจะไม่สามารถคงอยู่ยาวนานกว่าทรัพยากรเบื้องหลังได้ และการอ้างอิงไปยังทรัพยากรที่ส่งผ่านการ์ดก็จะไม่สามารถคงอยู่ยาวนานกว่าตัวการ์ดได้เช่นกัน เพื่อให้เห็นภาพการทำงานชัดเจนขึ้น ลองพิจารณาลายเซ็นของเมท็อด `deref` แบบระบุค่า lifetime ชัดเจน (โดยไม่ละเว้น lifetime elision):

```rust,ignore
fn deref<'a>(&'a self) -> &'a T {
    //..
}
```

การอ้างอิงไปยังทรัพยากรที่ส่งคืนกลับมาจะมี lifetime เดียวกันกับ `self` (`'a`) ดังนั้น borrow checker จึงช่วยรับประกันว่าอายุของการอ้างอิงไปยัง `T` จะต้องสั้นกว่าอายุของ `self` เสมอ

ข้อควรสังเกตคือ การนำ `Deref` trait มาใช้งานไม่ใช่หัวใจสำคัญที่ขาดไม่ได้ของแพตเทิร์นนี้ แต่มีไว้เพื่อเพิ่มความสะดวกสบายในการใช้งานออบเจกต์การ์ดเท่านั้น การเขียนเมท็อด `get` ธรรมดาบนตัวการ์ดก็ให้ผลลัพธ์ที่สมบูรณ์แบบไม่แพ้กัน

## ดูเพิ่มเติม

[สำนวนการคืนทรัพยากรใน destructor](../../idioms/dtor-finally.md)

RAII เป็นแพตเทิร์นที่พบเห็นได้ทั่วไปในภาษา C++:
[cppreference.com](http://en.cppreference.com/w/cpp/language/raii),
[wikipedia][wikipedia]

[wikipedia]: https://en.wikipedia.org/wiki/Resource_Acquisition_Is_Initialization

[Style guide entry](https://doc.rust-lang.org/1.0.0/style/ownership/raii.html)
(ปัจจุบันเป็นเพียงหน้าว่าง)
