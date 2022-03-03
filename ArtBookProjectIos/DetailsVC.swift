//
//  DetailsVC.swift
//  ArtBookProjectIos
//
//  Created by L60809MAC on 1.03.2022.
//

import UIKit
import CoreData

class DetailsVC: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate{

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var nameText: UITextField!
    @IBOutlet weak var artistText: UITextField!
    @IBOutlet weak var yearText: UITextField!
    @IBOutlet weak var saveButton: UIButton!
    
    var chosenPainting = ""
    var chosenPaintingId : UUID?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if chosenPainting != "" {
            
            saveButton.isHidden = true // tableView da veriye tıklandığında gelen ekranda save butonu görünmez
            
            //Boş değilse veri çekecek
            
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appDelegate.persistentContainer.viewContext
            
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Paintings")
            
            let idString = chosenPaintingId?.uuidString
            
            fetchRequest.predicate = NSPredicate(format: "id = %@", idString!) // id si idString e eşit olanı getir
            
            fetchRequest.returnsObjectsAsFaults = false
            
            do {
                let results = try context.fetch(fetchRequest)
                
                if results.count > 0 {
                    
                    for result in results as! [NSManagedObject] {
                        
                        if let name = result.value(forKey: "name") as? String {
                            nameText.text = name
                        }
                        
                        if let artist = result.value(forKey: "artist") as? String {
                            artistText.text = artist
                        }
                        
                        if let year = result.value(forKey: "year") as? Int {
                            yearText.text = String(year)
                        }
                        
                        if let imageData = result.value(forKey: "image") as? Data {
                            let image = UIImage(data: imageData)
                            imageView.image = image
                        }
                        
                    }
                    
                }
                
            } catch {
                print("hata var")
            }
            
            
        } else {
            saveButton.isHidden = false
            saveButton.isEnabled = false
            nameText.text = ""
            artistText.text = ""
            yearText.text = ""
        }
        
        // Recognizers
        // Kullanıcının yaptığı hareketleri algılayan recognizer (uzun tıklama, tek tık gibi)
        // app içerisinde herhangi bir yere tıklandığında klavyeyi kapatmayı yapıyoruz
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        view.addGestureRecognizer(gestureRecognizer) // klavye haricinde nereye tıklanırsa tıklansın klavye kapanacak
        
        // kullanıcı imageview a tıklayabiliyor mu
        imageView.isUserInteractionEnabled = true
        let imageTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(selectImage))
        imageView.addGestureRecognizer(imageTapRecognizer) // oluşturduğumuz imageTapRecognizer ı imageView a ekledik
        
    }
    
    @objc func selectImage() { // fotoğraf seçildiğinde çalışacak fonksiyon
        let picker = UIImagePickerController() // kullanıcının resim video gibi şeyleri alması için medya kütüphanesine erişmek için kullanılan sınıf
        picker.delegate = self // fotoğraflara ulaşabilmek için picker kullanıyoruz, picker ı kullanabilmek için de (UIImagePickerControllerDelegate, UINavigationControllerDelegate) bu iki sınıfı tanımlıyoruz
        picker.sourceType = .photoLibrary // fotoğrafa nereden ulaşacağını belirtiyoruz
        picker.allowsEditing = true // kullanıcı seçtiği fotoğrafı değiştirebilir (zoom, kırpma vs yapılabilir)
        present(picker, animated: true, completion: nil) // uyarı mesajı gibi picker görünecek
    }
    
    // kullanıcı galeriden resmi seçtikten sonrra ne olacak buraya yazıyoruz
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        imageView.image = info[.originalImage] as? UIImage // seçilen görseli orijinal olarak aldık ve Any istediği için UIImage a cast ettik, kullanıcı galeriden fotoğraf seçmeden de çıkabilir fotoğraf harici bir şey de seçebilir o yüzden as! kullanmadık as? kullandık
        saveButton.isEnabled = true
        self.dismiss(animated: true, completion: nil) // picker ı burada kapattık
    }
    
    @objc func hideKeyboard() { // klavyeyi gizle fonksiyonu
        view.endEditing(true) // klavye açıksa kapatacaktır
    }
    
    @IBAction func saveButtonClicked(_ sender: Any) {
        
        // AppDelegate da ki saveContext () a ulaşabilmemiz için AppDelegate ı değişken olarak tanımlamamız gerekiyor
        let appDelegate = UIApplication.shared.delegate as! AppDelegate // Dosyalar kısmında ki AppDelegate ı burada değişken gibi tanımladık
        let context = appDelegate.persistentContainer.viewContext // bu kontext i kullanarak AppDelegate da ki fonksiyonları kullanabiliriz
        
        // context in içine ne koyacağımızı belirtiyoruz
        let newPainting = NSEntityDescription.insertNewObject(forEntityName: "Paintings", into: context)
        
        // Paintings ENTITIES in içine veriyi kaydediyoruz
        //Attributes
        newPainting.setValue(nameText.text!, forKey: "name") // bir değer ve anahtar değer istiyor, forKey ler ArtBookPrjectIos da belirttiğimiz attributes lerin aynısı olmalı (artist, id, image, name, year)
        newPainting.setValue(artistText.text, forKey: "artist")
        
        if let year = Int(yearText.text!) { // kullanıcının farklı bir şey girmesini önlemek için bu kontrolü yaptk
            newPainting.setValue(year, forKey: "year") // Burada year ı Int olarak tanımladığımız için ınt e çeviriyoruz
        }
        
        newPainting.setValue(UUID(), forKey: "id") //Her seferinde bu işlem yapıldığında UUID() kendisi baştan bir unic id oluşturup buraya kaydedecek
        
        // görseli dataya çevirip kaydedeceğiz
        let data = imageView.image!.jpegData(compressionQuality: 0.5) //görseli data (veriye) çevirir,compressionQuality: <#T##CGFloat#> görselin ne kadar küçültüleceğini belirtiyoruz
        newPainting.setValue(data, forKey: "image")
        
        // context i kullanarak verileri (name, artist, year, id, image) kaydediyoruz
        do { // context.save() yazdığımızda hata olabileceği için try catch içine yazıyoruz, hatayı yakalayıp göstersin diye
            try context.save()
            print("kaydettim")
        } catch {
            print("error")
        }
        
        // Kaydetme işi bittikten sonra, kaydet butonuna basıldığında
        
        //NotificationCenter diğer viewController lara mesaj gönderme olanağı sağlıyor
        
        NotificationCenter.default.post(name: NSNotification.Name("newData"), object: nil) // Buradan viewController a mesaj gönderiyoruz, viewController da aldığı mesajdan sonra ne yapılacağını yazıyoruz (viewController bu mesajı aldığında getData yapacak ve kaydedilen görselin verileri çağırılıp tableView dda görünecek)
        
        //viewController a gitme
        
        self.navigationController?.popViewController(animated: true) //Bir önceki viewController a geri gider
        
    }
    

}
