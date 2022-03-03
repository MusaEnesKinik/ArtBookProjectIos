//
//  ViewController.swift
//  ArtBookProjectIos
//
//  Created by L60809MAC on 1.03.2022.
//

import UIKit
import CoreData

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    
    var nameArray = [String]()
    var idArray = [UUID]()
    
    var selectedPainting = ""
    var selectedPaintingId : UUID?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        tableView.delegate = self
        tableView.dataSource = self
        
        // viewController üzerinde ki navigationBar üzerine detailsVC ekranına yönlendirmesi için buton koyuyoruz
        
        navigationController?.navigationBar.topItem?.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.add, target: self, action: #selector(addButtonClicked)) // viewController da navigationBar ın en üst kısmına uaştık
        
        getData() // getData fonksiyonunu çağırdık
        
    }
    
    override func viewWillAppear(_ animated: Bool) { //viewController her açıldığında çalışmasını istediğimiz kodu yazıyoruz
        //DetailsVC de kaydet butonunda gönderdiğimiz mesajı alınca burada getData yaptık ve kaydedilen veriyi tableView her açıldığında görmeyi sağladık
        NotificationCenter.default.addObserver(self, selector: #selector(getData), name: NSNotification.Name(rawValue: "newData"), object: nil)
    }
    
    @objc func getData() { // core data dan verileri çekeceğimiz yer
        
        //dizileri temizledik, bu sayede tableView tekrar açılduığında veriler iki kez görünmeyecek
        nameArray.removeAll(keepingCapacity: false)
        idArray.removeAll(keepingCapacity: false)
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        // çekme işlemi
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Paintings")
        fetchRequest.returnsObjectsAsFaults = false // ayar yaptık, işlemin hızlanması için
        
        do {
            let results = try context.fetch(fetchRequest) // context.fetch(fetchRequest) in geri döndüreceği şey dizi, hata verebileceği için try catch yaptık
            if results.count > 0 {
                
                // içinde ki elemanları inceleyebilmek için for loop kullanmamız gerekiyor, ordada kullanılabilmesi içinde dönen diziyi results değişkenine atadık
                for result in results as! [NSManagedObject] { //tek bir results a odaklanmak (tek tek çekmek) için as! [NSManagedObject] e cast ettik
                    if let name = result.value(forKey: "name") as? String { // name anahtar kelimesini vererek isme ulaştık, bunu String olarak cast edebilirse
                        self.nameArray.append(name) // nameArray dizisine ismi ekledik
                    }
                    if let id = result.value(forKey: "id") as? UUID { //id anahtar kelimesini vererek id ye ulaştık, bunu UUID olarak cast ederse
                        self.idArray.append(id) // idArray dizisine akleyecek
                    }
                    
                    //tableView a yeni veri eklendiğinde görünmesi için güncelliyoruz
                    self.tableView.reloadData() //yeni bir veri geldi kendini güncelle demek
                    
                }
                
            }
            
            
        } catch {
            print("error")
        }
        
        
    }

    @objc func addButtonClicked() {
        selectedPainting = ""
        performSegue(withIdentifier: "toDetailsVC", sender: nil)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { //tableview da kaç satır olacağını belirtiyoruz
        return nameArray.count // nameArray dizisinin elemanı kadar gösterileccek
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell { //her satırın içinde ne olacak onu belirtiyoruz
        let cell = UITableViewCell()
        cell.textLabel?.text = nameArray[indexPath.row] // nameArray dizisinin kaçıncı sırasına geliyorsa onu gösterecek
        return cell
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toDetailsVC" {
            let destinationVC = segue.destination as! DetailsVC
            destinationVC.chosenPainting = selectedPainting
            destinationVC.chosenPaintingId = selectedPaintingId
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) { //bir veriye tıklandığında sgue yapacak
        selectedPainting = nameArray[indexPath.row]
        selectedPaintingId = idArray[indexPath.row]
        performSegue(withIdentifier: "toDetailsVC", sender: nil)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) { //tableView da veriyi sola çekip silme işlemi
        
        if editingStyle == .delete { //veri silmeye çalışoyorsa
            
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appDelegate.persistentContainer.viewContext
            
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Paintings")
            
            let idString = idArray[indexPath.row].uuidString
            
            fetchRequest.predicate = NSPredicate(format: "id =%@", idString)
            
            fetchRequest.returnsObjectsAsFaults = false
            
            do {
                let results =  try context.fetch(fetchRequest)
                if results.count > 0 {
                    for result in results as! [NSManagedObject] {
                        if let id = result.value(forKey: "id") as? UUID {
                            if id == idArray[indexPath.row] {
                                context.delete(result)
                                nameArray.remove(at: indexPath.row)
                                idArray.remove(at: indexPath.row)
                                self.tableView.reloadData()
                                
                                do {
                                    try context.save()
                                } catch {
                                    print("hata var")
                                }
                                
                                break
                                
                            }
                        }
                    }
                }
            } catch {
                print("hata var")
            }
            
            
        }
        
    }
    
}

