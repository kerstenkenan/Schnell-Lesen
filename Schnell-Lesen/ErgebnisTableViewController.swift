//
//  MyTableViewController.swift
//  Schnell-Lesen
//
//  Created by Kersten Weise on 05.12.18.
//  Copyright © 2018 Kersten Weise. All rights reserved.
//

import UIKit
import CoreData
import PDFKit
import MessageUI

class ErgebnisTableViewController: UITableViewController, NSFetchedResultsControllerDelegate {
    
    var container: NSPersistentContainer? = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer
    
    var sortByDate = true
    
    var frc : NSFetchedResultsController<Ergebnis>? {
        var resultController : NSFetchedResultsController<Ergebnis>?
        let request : NSFetchRequest<Ergebnis> = Ergebnis.fetchRequest()
        if sortByDate {
            request.sortDescriptors = [NSSortDescriptor(key: "datum", ascending: false)]
        } else {
            request.sortDescriptors = [NSSortDescriptor(key: "punkte", ascending: false)]
        }
        if let context = container?.viewContext {
            resultController = NSFetchedResultsController<Ergebnis>(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: "sectionIdentifier", cacheName: nil)
            resultController?.delegate = self
            do {
                try resultController?.performFetch()
            } catch let err {
                print("NSFetchedResultsController couldn't fetch any results: \(err)")
            }
        }
        return resultController
    }
    
    lazy var segCtrl : UISegmentedControl = {
        let seg = UISegmentedControl(items: ["Datum", "Punkte"])
        seg.selectedSegmentIndex = 0
        seg.addTarget(self, action: #selector(segCtrlChanged), for: .valueChanged)
        return seg
    }()
        
    var documentURL: URL? {
        return try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
    }
    
    var zaehler = 0
    
    var activeObserver : NSObjectProtocol?
    
    let colorArr : [UIColor] = [#colorLiteral(red: 0.3411764801, green: 0.6235294342, blue: 0.1686274558, alpha: 1), #colorLiteral(red: 0.1764705926, green: 0.4980392158, blue: 0.7568627596, alpha: 1), #colorLiteral(red: 0.9529411793, green: 0.6862745285, blue: 0.1333333403, alpha: 1), #colorLiteral(red: 0.7450980544, green: 0.1568627506, blue: 0.07450980693, alpha: 1)]
 
    // MARK: Lifecycle
    
    override func viewDidLoad() {
        navigationItem.title = "Ergebnisse"
        navigationController?.navigationBar.prefersLargeTitles = true
        self.navigationItem.titleView = segCtrl
        self.tableView.rowHeight = 60
    }
    
    override func viewWillAppear(_ animated: Bool) {
        activeObserver = NotificationCenter.default.addObserver(forName: .UIApplicationDidBecomeActive, object: nil, queue: .main, using: { _ in
            self.tableView.reloadData()
        })
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if let observer = activeObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    @objc func segCtrlChanged() {
        switch segCtrl.selectedSegmentIndex {
        case 0:
            sortByDate = true
        case 1:
            sortByDate = false
        default: break
        }
        self.tableView.reloadData()
    }
    
    // MARK: Table
    
    func datumFomatieren(datum: NSDate, template: String) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.setLocalizedDateFormatFromTemplate(template)
        let datumString = formatter.string(from: datum as Date)
        return datumString
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return frc!.sections!.count == 0 ? 1 : frc!.sections!.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return frc!.sections!.count == 0 ? 0 : frc!.sections![section].numberOfObjects
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "Ergebniseintrag", for: indexPath) as! CustomTableViewCell
        if let obj = self.frc?.object(at: indexPath) {
            cell.backgroundColor = colorArr[zaehler]
            if obj.words {
                cell.namenLabel.text = "\(obj.benutzer?.name ?? "Namenlos") (Wörter)"
            } else {
                cell.namenLabel.text = "\(obj.benutzer?.name ?? "Namenlos") (Sätze)" 

            }
            if let datum = obj.datum {
            cell.datumLabel.text = datumFomatieren(datum: datum, template: "ddMMYY")
            }
            cell.punkteLabel.text = String("Punkte: \(obj.punkte)")
            cell.minutenLabel.text = String("Minuten: \(obj.minuten)")
            cell.rundenLabel.text = String("Runden: \(obj.runden)")
        }
        if zaehler >= 3 {
            zaehler = 0
        } else {
        zaehler += 1
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        var sectionTitle : String!
        if let sects = frc?.sections {
            if sects.isEmpty {
                sectionTitle = "Keine Einträge"
            } else {
                let sectName = sects[section].name
                if let datum = Int(sectName) {
                    let year = datum / 1000
                    let month = datum - (year * 1000)
                    var dateComp = DateComponents()
                    dateComp.year = year
                    dateComp.month = month
                    if let date = Calendar.current.date(from: dateComp) {
                        sectionTitle = datumFomatieren(datum: date as NSDate, template: "MMMM YYYY")
                    }
                }
            }
        }
        return sectionTitle
    }
        
    // MARK: Buttons
    
    @IBAction func readyButtonPressed(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    
    @IBAction func loescheListe(_ sender: UIBarButtonItem) {
        if let context = container?.viewContext {
            if let eintraege = try? context.fetch(Ergebnis.fetchRequest()) as! [NSManagedObject] {
                print("zu löschende Einträge: \(eintraege)")
                eintraege.forEach({ (eintrag) in
                    context.delete(eintrag)
                })
                try? context.save()
            }
        }
        tableView.reloadData()
    }
    
    // MARK: PDF
    
    func erstellePDF() -> Data? {
        var horizontalStacks = [UIStackView]()
        let logo = #imageLiteral(resourceName: "Lesen_Icon_small")
        let logoTitel = NSAttributedString(string: "Lesen Lernen App von ©Kersten Weise", attributes: [NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 12)])
        
        if let allObj = frc?.fetchedObjects  {
            if allObj.isEmpty {
                let alertAction = UIAlertAction(title: "OK", style: .default)
                let alert = UIAlertController(title: "Leere Liste", message: "Keine Einträge zum exportieren vorhanden.", preferredStyle: .alert)
                alert.addAction(alertAction)
                self.present(alert, animated: true)
            } else {
                allObj.forEach { (ergebnis) in
                    let horizontalStack = UIStackView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 60))
                    horizontalStack.axis = .horizontal
                    horizontalStack.distribution = .fillEqually
                    horizontalStack.spacing = 5
                    let background = UIView(frame: horizontalStack.frame)
                    background.backgroundColor = colorArr[zaehler]
                    horizontalStack.addSubview(background)
                    
                    let namenLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 350, height: 40))
                    namenLabel.font = .boldSystemFont(ofSize: 25)
                    namenLabel.adjustsFontSizeToFitWidth = true
                    if ergebnis.words {
                        namenLabel.text = "\(ergebnis.benutzer?.name ?? "Namenlos") (Wörter)"
                    } else {
                        namenLabel.text = "\(ergebnis.benutzer?.name ?? "Namenlos") (Sätze)"
                    }
                    horizontalStack.addArrangedSubview(namenLabel)
                    
                    let dateLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 40))
                    dateLabel.font = .boldSystemFont(ofSize: 25)
                    dateLabel.adjustsFontSizeToFitWidth = true
                    dateLabel.text = datumFomatieren(datum: ergebnis.datum!, template: "ddMMMMYYYY")
                    horizontalStack.addArrangedSubview(dateLabel)
                    
                    let minutesLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 40))
                    minutesLabel.font = .boldSystemFont(ofSize: 25)
                    minutesLabel.adjustsFontSizeToFitWidth = true
                    minutesLabel.text = "Minuten: \(ergebnis.minuten)"
                    horizontalStack.addArrangedSubview(minutesLabel)
                    
                    let pointLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 40))
                    pointLabel.font = .boldSystemFont(ofSize: 25)
                    pointLabel.adjustsFontSizeToFitWidth = true
                    pointLabel.text = "Punkte: \(ergebnis.punkte)"
                    horizontalStack.addArrangedSubview(pointLabel)

                    let roundLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 40))
                    roundLabel.font = .boldSystemFont(ofSize: 25)
                    roundLabel.adjustsFontSizeToFitWidth = true
                    roundLabel.text = "Runden: \(ergebnis.runden)\n\n"
                    horizontalStack.addArrangedSubview(roundLabel)
                    
                    horizontalStacks.append(horizontalStack)
                                                            
                    if zaehler >= 3 {
                        zaehler = 0
                    } else {
                    zaehler += 1
                    }
                }
            }
        }
        
        let horizontalStacksHeight : CGFloat = {
            var horizontalHeight : CGFloat = 0
            horizontalStacks.forEach { stack in
                horizontalHeight += stack.frame.size.height
            }
            return horizontalHeight
        }()
        
        let verticalStack = UIStackView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: horizontalStacksHeight))
        verticalStack.axis = .vertical
        verticalStack.distribution = .fillEqually
        for stack in horizontalStacks {
            verticalStack.addArrangedSubview(stack)
        }
        
        
        let imageRenderer = UIGraphicsImageRenderer(bounds: verticalStack.bounds)
        let image = imageRenderer.image { context in
            verticalStack.layer.render(in: context.cgContext)
        }
        
//        let imageView = UIImageView(image: image)
//        imageView.frame.origin.y = self.view.frame.midY
//        self.view.addSubview(imageView)
        
        let pdfRenderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: verticalStack.frame.size.width, height: verticalStack.frame.height + 200))
        
        let pdf = pdfRenderer.pdfData { (context) in
            context.beginPage()
            logo.draw(in: CGRect(x: 20, y: 20, width: 120, height: 120))
            logoTitel.draw(in: CGRect(x: 20, y: 140, width: 400, height: 200))
            image.draw(in: CGRect(x: 0, y: 200, width: verticalStack.frame.size.width, height: verticalStack.frame.size.height))
        }
        return pdf
    }
    
    // MARK: IBActions
    
    @IBAction func exportPDF(_ sender: UIBarButtonItem) {
        let datum = save()
        if let url = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("LesenLernenApp_\(datum).pdf") {
            let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
            activityVC.popoverPresentationController?.barButtonItem = sender
            self.present(activityVC, animated: true)
        }
    }
    
    @IBAction func closeController(_ sender: Any) {
        if self.presentingViewController as? ErgebnisViewController != nil {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let einstellungVC = storyboard.instantiateViewController(withIdentifier: "NaviEinstellungen")
            einstellungVC.modalPresentationStyle = .fullScreen
            self.present(einstellungVC, animated: true, completion: nil)
        } else {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    func save() -> String {
        let datum = datumFomatieren(datum: NSDate(), template: "ddMMYYYY_HH:mm")
        if let pdfData = erstellePDF() {
            if let url = documentURL {
                do {
                    try pdfData.write(to: url.appendingPathComponent("LesenLernenApp_\(datum).pdf"), options: .atomic)
                    print("saved sucessfully")
                } catch let error {
                    print("couldn't save: \(error)")
                }
            }
        }
        return datum
    }
}

extension ErgebnisTableViewController {
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.tableView.beginUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        switch type {
        case .insert:
            self.tableView.insertSections(IndexSet(integer: sectionIndex), with: .fade)
            break
        case .delete:
            if sectionIndex <= 1 {
                return
            } else {
                self.tableView.deleteSections(IndexSet(integer: sectionIndex), with: .fade)
            }
        default:
            break
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .delete:
            self.tableView.deleteRows(at: [indexPath!], with: .fade)
        case .insert:
            self.tableView.insertRows(at: [newIndexPath!], with: .fade)
        default:
            break
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.tableView.endUpdates()
    }
}

