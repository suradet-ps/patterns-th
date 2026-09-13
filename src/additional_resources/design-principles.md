# หลักการออกแบบ

## ภาพรวมสั้นๆ ของหลักการออกแบบที่พบบ่อย

---

## [SOLID](https://en.wikipedia.org/wiki/SOLID)

- [หลักความรับผิดชอบเดี่ยว (Single Responsibility Principle - SRP)](https://en.wikipedia.org/wiki/Single-responsibility_principle):
  คลาสควรมีความรับผิดชอบเพียงอย่างเดียว นั่นคือ การเปลี่ยนแปลงในส่วนเดียวของ
  ข้อกำหนดซอฟต์แวร์เท่านั้นที่ควรส่งผลต่อข้อกำหนดของคลาส
- [หลักเปิด/ปิด (Open/Closed Principle - OCP)](https://en.wikipedia.org/wiki/Open%E2%80%93closed_principle):
  "เอนทิตีของซอฟต์แวร์... ควรเปิดสำหรับการขยาย แต่ปิดสำหรับการแก้ไข"
- [หลักการแทนที่ของลิสคอฟ (Liskov Substitution Principle - LSP)](https://en.wikipedia.org/wiki/Liskov_substitution_principle):
  "ออบเจกต์ในโปรแกรมควรแทนที่ได้ด้วยอินสแตนซ์ของชนิดย่อย โดยไม่ทำให้ความ
  ถูกต้องของโปรแกรมนั้นเปลี่ยนไป"
- [หลักการแยกอินเทอร์เฟซ (Interface Segregation Principle - ISP)](https://en.wikipedia.org/wiki/Interface_segregation_principle):
  "อินเทอร์เฟซเฉพาะไคลเอนต์หลายตัวย่อมดีกว่าอินเทอร์เฟซเอนกประสงค์ตัวเดียว"
- [หลักการผกผันการพึ่งพา (Dependency Inversion Principle - DIP)](https://en.wikipedia.org/wiki/Dependency_inversion_principle):
  ควร "พึ่งพานามธรรม ไม่ใช่[สิ่ง]ที่เป็นรูปธรรม"

## [CRP (Composite Reuse Principle) หรือ การประกอบดีกว่าการสืบทอด](https://en.wikipedia.org/wiki/Composition_over_inheritance)

"หลักการที่ว่าคลาสควรสนับสนุนพฤติกรรมพอลิมอร์ฟิกและการใช้โค้ดซ้ำผ่านการประกอบ (โดยการบรรจุอินสแตนซ์ของคลาสอื่นซึ่งอิมพลีเมนต์ฟังก์ชันการทำงานที่ต้องการ) มากกว่าการสืบทอดจากคลาสฐานหรือคลาสแม่" -
Knoernschild, Kirk (2002). Java Design - Objects, UML, and Process

## [DRY (Don't Repeat Yourself)](https://en.wikipedia.org/wiki/Don%27t_repeat_yourself)

"ความรู้ทุกชิ้นต้องมีการนำเสนอที่เป็นเอกภาพ ชัดเจน และเชื่อถือได้เพียงหนึ่งเดียวภายในระบบ"

## [หลักการ KISS](https://en.wikipedia.org/wiki/KISS_principle)

ระบบส่วนใหญ่ทำงานได้ดีที่สุดเมื่อถูกทำให้เรียบง่ายแทนที่จะซับซ้อน ดังนั้น ความเรียบง่ายจึงควรเป็นเป้าหมายสำคัญในการออกแบบ และควรหลีกเลี่ยงความซับซ้อนที่ไม่จำเป็น

## [กฎของเดเมเทอร์ (Law of Demeter - LoD)](https://en.wikipedia.org/wiki/Law_of_Demeter)

ออบเจกต์หนึ่งควรตั้งสมมติฐานเกี่ยวกับโครงสร้างหรือคุณสมบัติของสิ่งอื่น (รวมถึงองค์ประกอบย่อยของมัน) ให้น้อยที่สุด ตามหลักการ "การซ่อนข้อมูล (information hiding)"

## [การออกแบบตามสัญญา (Design by contract - DbC)](https://en.wikipedia.org/wiki/Design_by_contract)

นักออกแบบซอฟต์แวร์ควรนิยามข้อกำหนดอินเทอร์เฟซที่เป็นทางการ แม่นยำ และตรวจสอบได้ สำหรับองค์ประกอบซอฟต์แวร์ ซึ่งขยายนิยามปกติของชนิดข้อมูลนามธรรมด้วยเงื่อนไขก่อน (preconditions) เงื่อนไขหลัง (postconditions) และ invariant

## [การห่อหุ้ม (Encapsulation)](https://en.wikipedia.org/wiki/Encapsulation_(computer_programming))

การรวมข้อมูลเข้ากับเมท็อดที่ดำเนินการบนข้อมูลนั้น หรือการจำกัดการเข้าถึงโดยตรงต่อองค์ประกอบบางส่วนของออบเจกต์ การห่อหุ้มใช้เพื่อซ่อนค่าหรือสถานะของออบเจกต์ข้อมูลแบบมีโครงสร้างไว้ภายในคลาส ป้องกันไม่ให้บุคคลที่ไม่ได้รับอนุญาตเข้าถึงโดยตรง

## [การแยกคำสั่ง-คำถาม (Command-Query-Separation - CQS)](https://en.wikipedia.org/wiki/Command%E2%80%93query_separation)

"ฟังก์ชันไม่ควรก่อผลข้างเคียงเชิงนามธรรม... มีเพียงคำสั่ง (procedure) เท่านั้นที่ได้รับอนุญาตให้ก่อผลข้างเคียง" - Bertrand Meyer: Object-Oriented Software Construction

## [หลักการสร้างความประหลาดใจน้อยที่สุด (Principle of least astonishment - POLA)](https://en.wikipedia.org/wiki/Principle_of_least_astonishment)

องค์ประกอบของระบบควรมีพฤติกรรมในแบบที่ผู้ใช้ส่วนใหญ่คาดหวังว่ามันจะเป็น พฤติกรรมนั้นไม่ควรทำให้ผู้ใช้ประหลาดใจหรือแปลกใจ

## Linguistic-Modular-Units

"โมดูลต้องสอดคล้องกับหน่วยทางวากยสัมพันธ์ในภาษาที่ใช้" - Bertrand
Meyer: Object-Oriented Software Construction

## Self-Documentation

"ผู้ออกแบบโมดูลควรพยายามทำให้ข้อมูลทั้งหมดเกี่ยวกับโมดูลเป็นส่วนหนึ่งของโมดูลเอง" - Bertrand Meyer: Object-Oriented Software
Construction

## Uniform-Access

"บริการทั้งหมดที่โมดูลนำเสนอควรเข้าถึงได้ผ่านสัญกรณ์ที่สม่ำเสมอ ซึ่งไม่เผยให้รู้ว่าพวกมันถูกอิมพลีเมนต์ผ่านการจัดเก็บหรือผ่านการคำนวณ" - Bertrand Meyer: Object-Oriented Software Construction

## Single-Choice

"เมื่อใดที่ระบบซอฟต์แวร์ต้องรองรับชุดทางเลือกหนึ่ง ควรมีเพียงโมดูลเดียวในระบบที่รู้รายการทางเลือกทั้งหมด" - Bertrand Meyer:
Object-Oriented Software Construction

## Persistence-Closure

"เมื่อใดที่กลไกการจัดเก็บจัดเก็บออบเจกต์ มันต้องจัดเก็บสิ่งที่ออบเจกต์นั้นพึ่งพาไปด้วย เมื่อใดที่กลไกการดึงข้อมูลดึงออบเจกต์ที่จัดเก็บไว้ก่อนหน้านี้ มันต้องดึงสิ่งที่ออบเจกต์นั้นพึ่งพาซึ่งยังไม่ถูกดึงมาด้วย" - Bertrand Meyer: Object-Oriented Software Construction
