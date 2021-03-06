

import UIKit

func delay(_ delay:Double, closure:@escaping ()->()) {
    let when = DispatchTime.now() + delay
    DispatchQueue.main.asyncAfter(deadline: when, execute: closure)
}


// I don't see how else to assert that the status bar should be hidden,
// other than to write my own UISearchController subclass

class MySearchController : UISearchController {
    override var prefersStatusBarHidden : Bool {
        return true
    }
}

class MySearchContainerViewController : UISearchContainerViewController {
    override func viewDidLayoutSubviews() {
        print("here")
        //self.searchController.searchBar.frame = CGRect(x: 0, y: 40, width: 300, height: 100)

    }
}

class MyContainerViewController : UIViewController {
    let searchController : UISearchController
    init(searchController:UISearchController) {
        self.searchController = searchController
        super.init(nibName:nil, bundle:nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class MyParentViewController : UIViewController {
    var didSetup = false
    let searcher : UISearchController
    init(searcher:UISearchController) {
        self.searcher = searcher
        super.init(nibName:nil, bundle:nil)
        self.edgesForExtendedLayout = []
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if !didSetup {
            didSetup = true
            let scvc = MyContainerViewController(searchController: self.searcher)
            self.addChildViewController(scvc)
            scvc.view.frame = self.view.bounds
            scvc.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            self.view.addSubview(scvc.view)
            let b = searcher.searchBar
            b.sizeToFit()
            b.autoresizingMask = [.flexibleWidth]
            b.autocapitalizationType = .none
            scvc.view.addSubview(b)
            

            // hmm, this actually causes presentation and I can't seem to prevent it
            // scvc.didMove(toParentViewController: self)
        }
    }
    // just making sure it's all in order
    override func viewWillDisappear(_ animated: Bool) {
        print("disappear")
    }
    deinit {
        print("bye")
    }

}

class RootViewController : UITableViewController, UISearchBarDelegate {
    var sectionNames = [String]()
    var cellData = [[String]]()
    // var searcher : UISearchController!
    
    init() {
        super.init(nibName: nil, bundle: nil)
        let b = UIBarButtonItem(title: "Search", style: .plain, target: self, action: #selector(doSearch))
        self.navigationItem.rightBarButtonItem = b
    }
    
    func doSearch(_ sender: Any) {
        // construct container view controller

        let src = SearchResultsController(data: self.cellData)
        // instantiate a search controller and keep it alive
        let searcher = MySearchController(searchResultsController: src)
        // specify who the search controller should notify when the search bar changes
        searcher.searchResultsUpdater = src
        searcher.hidesNavigationBarDuringPresentation = false
        searcher.obscuresBackgroundDuringPresentation = false
        let vc = MyParentViewController(searcher:searcher)
        
        
        
        
        self.navigationController!.pushViewController(vc, animated:true)
        // self.present(vc, animated:true)
    }
        
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var prefersStatusBarHidden : Bool {
        return true
    }
    
    override func viewDidLoad() {
        let s = try! String(contentsOfFile: Bundle.main.path(forResource: "states", ofType: "txt")!)
        let states = s.components(separatedBy:"\n")
        var previous = ""
        for aState in states {
            // get the first letter
            let c = String(aState.characters.prefix(1))
            // only add a letter to sectionNames when it's a different letter
            if c != previous {
                previous = c
                self.sectionNames.append(c.uppercased())
                // and in that case also add new subarray to our array of subarrays
                self.cellData.append([String]())
            }
            self.cellData[self.cellData.count-1].append(aState)
        }
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        self.tableView.register(UITableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: "Header")
        
        self.tableView.sectionIndexColor = .white
        self.tableView.sectionIndexBackgroundColor = .red
        // self.tableView.sectionIndexTrackingBackgroundColor = .blue
        self.tableView.backgroundColor = .yellow // but the search bar covers that
        self.tableView.backgroundView = { // this will fix it
            let v = UIView()
            v.backgroundColor = .yellow
            return v
        }()
        
        /*

        // most rudimentary possible search interface
        // instantiate a view controller that will present the search results
        let src = SearchResultsController(data: self.cellData)
        // instantiate a search controller and keep it alive
        let searcher = MySearchController(searchResultsController: src)
        self.searcher = searcher
        // specify who the search controller should notify when the search bar changes
        searcher.searchResultsUpdater = src
        
        searcher.hidesNavigationBarDuringPresentation = false
        searcher.obscuresBackgroundDuringPresentation = false
 
 */
        
        /*
        // put the search controller's search bar into the interface
        let b = searcher.searchBar
        b.sizeToFit() // crucial, trust me on this one
        // b.scopeButtonTitles = ["Hey", "Ho"] // shows during search only; uncomment to see
        // (not used in this example; just showing the interface)
        // WARNING: do NOT call showsScopeBar! it messes things up!
        // (buttons will show during search if there are titles)
        b.autocapitalizationType = .none
        self.tableView.tableHeaderView = b
        self.tableView.reloadData()
        self.tableView.scrollToRow(at:
            IndexPath(row: 0, section: 0),
            at:.top, animated:false)
        // that's all! The rest is in SearchResultsController
 */
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return self.sectionNames.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.cellData[section].count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier:"Cell", for: indexPath) 
        let s = self.cellData[indexPath.section][indexPath.row]
        cell.textLabel!.text = s
        
        // this part is not in the book, it's just for fun
        var stateName = s
        stateName = stateName.lowercased()
        stateName = stateName.replacingOccurrences(of:" ", with:"")
        stateName = "flag_\(stateName).gif"
        let im = UIImage(named: stateName)
        cell.imageView!.image = im
        
        return cell
    }
    
    /*
    
    override func tableView(_ tableView: UITableView!, titleForHeaderInSection section: Int) -> String! {
    return self.sectionNames[section]
    }
    
    */
    // this is more "interesting"
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let h = tableView
            .dequeueReusableHeaderFooterView(withIdentifier:"Header")!
        if h.viewWithTag(1) == nil {
            
            h.backgroundView = UIView()
            h.backgroundView?.backgroundColor = .black
            let lab = UILabel()
            lab.tag = 1
            lab.font = UIFont(name:"Georgia-Bold", size:22)
            lab.textColor = .green
            lab.backgroundColor = .clear
            h.contentView.addSubview(lab)
            let v = UIImageView()
            v.tag = 2
            v.backgroundColor = .black
            v.image = UIImage(named:"us_flag_small.gif")
            h.contentView.addSubview(v)
            lab.translatesAutoresizingMaskIntoConstraints = false
            v.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                NSLayoutConstraint.constraints(withVisualFormat:
                    "H:|-5-[lab(25)]-10-[v(40)]",
                    metrics:nil, views:["v":v, "lab":lab]),
                NSLayoutConstraint.constraints(withVisualFormat:
                    "V:|[v]|",
                    metrics:nil, views:["v":v]),
                NSLayoutConstraint.constraints(withVisualFormat:
                    "V:|[lab]|",
                    metrics:nil, views:["lab":lab])
                ].flatMap{$0})
        }
        let lab = h.contentView.viewWithTag(1) as! UILabel
        lab.text = self.sectionNames[section]
        return h
        
    }
    
    /*
    override func tableView(_ tableView: UITableView!, willDisplayHeaderView view: UIView!, forSection section: Int) {
    println(view) // prove we are reusing header views
    }
    */
    
    override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return self.sectionNames
    }
}
