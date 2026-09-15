# หลักการออกแบบ

## ภาพรวมสั้นๆ ของหลักการออกแบบที่พบบ่อย

---

## [SOLID](https://en.wikipedia.org/wiki/SOLID)

- [หลักความรับผิดชอบเดี่ยว (Single Responsibility Principle - SRP)](https://en.wikipedia.org/wiki/Single-responsibility_principle):
  คลาสควรมีความรับผิดชอบเพียงเรื่องเดียว นั่นคือ การเปลี่ยนแปลงข้อกำหนดในส่วนใดส่วนหนึ่งของซอฟต์แวร์ ควรส่งผลกระทบต่อคลาสที่เกี่ยวข้องเพียงคลาสเดียวเท่านั้น
- [หลักเปิด/ปิด (Open/Closed Principle - OCP)](https://en.wikipedia.org/wiki/Open%E2%80%93closed_principle):
  "องค์ประกอบของซอฟต์แวร์... ควรเปิดให้สามารถขยายความสามารถเพิ่มเติมได้ (Open for extension) แต่ปิดกั้นการแก้ไขโค้ดเดิมภายใน (Closed for modification)"
- [หลักการแทนที่ของลิสคอฟ (Liskov Substitution Principle - LSP)](https://en.wikipedia.org/wiki/Liskov_substitution_principle):
  "ออบเจกต์ในโปรแกรมควรสามารถถูกแทนที่ด้วยอินสแตนซ์ของชนิดข้อมูลย่อย (Subtype) ได้ โดยไม่กระทบต่อความถูกต้องในการทำงานของโปรแกรมนั้น"
- [หลักการแยกอินเทอร์เฟซ (Interface Segregation Principle - ISP)](https://en.wikipedia.org/wiki/Interface_segregation_principle):
  "การมีอินเทอร์เฟซย่อยเฉพาะทางหลายตัวที่ตรงตามความต้องการของผู้เรียก ย่อมดีกว่าการมีอินเทอร์เฟซขนาดใหญ่เอนกประสงค์เพียงตัวเดียว"
- [หลักการผกผันการพึ่งพา (Dependency Inversion Principle - DIP)](https://en.wikipedia.org/wiki/Dependency_inversion_principle):
  โค้ดควร "พึ่งพานามธรรมหรือแอบสแตรกชัน (Abstractions) ไม่ใช่พึ่งพาการทำงานที่เป็นรูปธรรม (Concretions)"

## [CRP (Composite Reuse Principle) หรือ การประกอบดีกว่าการสืบทอด](https://en.wikipedia.org/wiki/Composition_over_inheritance)

"หลักการที่ว่าคลาสควรส่งเสริมพฤติกรรมแบบพอลิมอร์ฟิกและการนำโค้ดกลับมาใช้ซ้ำผ่านการประกอบออบเจกต์ (Composition — โดยบรรจุอินสแตนซ์ของคลาสอื่นที่ทำงานตามต้องการ) มากกว่าการสืบทอดคุณสมบัติ (Inheritance) จากคลาสแม่" —
Knoernschild, Kirk (2002). Java Design - Objects, UML, and Process

## [DRY (Don't Repeat Yourself)](https://en.wikipedia.org/wiki/Don%27t_repeat_yourself)

"องค์ความรู้หรือตรรกะทุกชิ้นภายในระบบ จะต้องมีตัวแทนที่ชัดเจน ไม่คลุมเครือ และเชื่อถือได้เพียงจุดเดียวเท่านั้น"

## [หลักการ KISS](https://en.wikipedia.org/wiki/KISS_principle)

ระบบส่วนใหญ่จะทำงานได้ดีและเสถียรที่สุดเมื่อถูกรักษาให้เรียบง่าย ไม่ซับซ้อน ดังนั้น ความเรียบง่ายจึงควรเป็นเป้าหมายสำคัญในการออกแบบ และควรหลีกเลี่ยงความซับซ้อนที่ไม่จำเป็นเสมอ

## [กฎของเดเมเทอร์ (Law of Demeter - LoD)](https://en.wikipedia.org/wiki/Law_of_Demeter)

ออบเจกต์หนึ่งควรล่วงรู้โครงสร้างหรือคุณสมบัติภายในของออบเจกต์อื่น (รวมถึงคอมโพเนนต์ย่อยของมัน) ให้น้อยที่สุด ตามหลักการ "การซ่อนข้อมูล (Information Hiding)"

## [การออกแบบตามสัญญา (Design by contract - DbC)](https://en.wikipedia.org/wiki/Design_by_contract)

นักออกแบบซอฟต์แวร์ควรกำหนดข้อกำหนดของอินเทอร์เฟซที่ชัดเจน แม่นยำ และตรวจสอบได้ สำหรับคอมโพเนนต์ของซอฟต์แวร์ ซึ่งขยายขอบเขตของชนิดข้อมูลนามธรรมด้วยเงื่อนไขก่อนเริ่มทำงาน (Preconditions), เงื่อนไขหลังทำงานสำเร็จ (Postconditions) และสัจพจน์ที่ไม่เปลี่ยนแปลง (Invariants)

## [การห่อหุ้ม (Encapsulation)](https://en.wikipedia.org/wiki/Encapsulation_(computer_programming))

การรวมกลุ่มข้อมูลเข้ากับเมท็อดที่ประมวลผลข้อมูลนั้น ตลอดจนการจำกัดการเข้าถึงองค์ประกอบภายในของออบเจกต์ การห่อหุ้มใช้เพื่อซ่อนสถานะหรือค่าของข้อมูลไว้ภายใน ป้องกันไม่ให้ส่วนภายนอกที่ไม่มีสิทธิ์เข้าถึงหรือแก้ไขข้อมูลได้โดยตรง

## [การแยกคำสั่ง-คำถาม (Command-Query-Separation - CQS)](https://en.wikipedia.org/wiki/Command%E2%80%93query_separation)

"ฟังก์ชันไม่ควรสร้างผลข้างเคียง (Side effects)... มีเพียงคำสั่งที่ดำเนินการ (Procedures/Commands) เท่านั้นที่อนุญาตให้ก่อผลข้างเคียงได้" — Bertrand Meyer: Object-Oriented Software Construction

## [หลักการสร้างความประหลาดใจน้อยที่สุด (Principle of least astonishment - POLA)](https://en.wikipedia.org/wiki/Principle_of_least_astonishment)

คอมโพเนนต์ของระบบควรทำงานในลักษณะที่ผู้ใช้ส่วนใหญ่คาดหมาย พฤติกรรมของมันไม่ควรสร้างความประหลาดใจหรือความสับสนให้แก่ผู้ใช้งาน

## Linguistic-Modular-Units

"โมดูลต้องสอดคล้องกับหน่วยทางวากยสัมพันธ์ (Syntactic Units) ในภาษาโปรแกรมที่ใช้งานจริง" — Bertrand
Meyer: Object-Oriented Software Construction

## Self-Documentation

"ผู้ออกแบบโมดูลควรพยายามทำให้ข้อมูลรายละเอียดทั้งหมดของโมดูล บรรจุอยู่ภายในตัวโมดูลนั้นเอง" — Bertrand Meyer: Object-Oriented Software
Construction

## Uniform-Access

"บริการทั้งหมดที่โมดูลนำเสนอควรเข้าถึงได้ผ่านรูปแบบสัญกรณ์ที่สม่ำเสมอ โดยไม่เผยให้เห็นว่าบริการนั้นทำงานผ่านการดึงข้อมูลที่จัดเก็บไว้หรือผ่านการคำนวณขึ้นใหม่" — Bertrand Meyer: Object-Oriented Software Construction

## Single-Choice

"เมื่อใดก็ตามที่ระบบซอฟต์แวร์ต้องรองรับชุดทางเลือก ควรมีเพียงโมดูลเดียวในระบบที่ล่วงรู้รายการทางเลือกทั้งหมดอย่างครบถ้วน" — Bertrand Meyer:
Object-Oriented Software Construction

## Persistence-Closure

"เมื่อกลไกการจัดเก็บบันทึกออบเจกต์ใดลงระบบ มันจะต้องจัดเก็บออบเจกต์ทั้งหมดที่ออบเจกต์นั้นพึ่งพาไปด้วย และเมื่อกลไกการอ่านข้อมูลดึงออบเจกต์ที่บันทึกไว้ขึ้นมา มันจะต้องดึงออบเจกต์ที่เกี่ยวข้องซึ่งยังไม่ได้ถูกดึงมาขึ้นมาด้วยเช่นกัน" — Bertrand Meyer: Object-Oriented Software Construction
