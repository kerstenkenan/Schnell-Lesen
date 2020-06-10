//
//  AnleitungPageViewController.swift
//  Schnell-Lesen
//
//  Created by Kersten Weise on 27.08.18.
//  Copyright © 2018 Kersten Weise. All rights reserved.
//

import UIKit

class AnleitungPageViewController: UIPageViewController, UIPageViewControllerDelegate, UIPageViewControllerDataSource {

    lazy var ordererdViewcontrollers : [UIViewController] = {
        return [self.newVC(vc: "seite1"), self.newVC(vc: "seite2")]
    }()
    
    var pageCtrl = UIPageControl()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.dataSource = self
        self.delegate = self
        
        if let firstVC = ordererdViewcontrollers.first {
            setViewControllers([firstVC], direction: .forward, animated: true, completion: nil)
        }
        
        setpageCtrl()
    }
    
    func setpageCtrl() {
        pageCtrl = UIPageControl(frame: CGRect(x: 0, y: UIScreen.main.bounds.maxY - 50, width: UIScreen.main.bounds.width, height: 50))
        pageCtrl.numberOfPages = ordererdViewcontrollers.count
        pageCtrl.currentPage = 0
        pageCtrl.tintColor = UIColor.blue
        pageCtrl.pageIndicatorTintColor = UIColor.lightGray.withAlphaComponent(0.5)
        pageCtrl.currentPageIndicatorTintColor = UIColor.blue
        self.view.addSubview(pageCtrl)
    }
    
    func newVC(vc: String) -> UIViewController {
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: vc)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let vcIndex = ordererdViewcontrollers.index(of: viewController) else {
            return nil
        }
        
        let prevIndex = vcIndex - 1
        
        guard prevIndex >= 0 else {
            return nil
        }
        
        guard ordererdViewcontrollers.count > prevIndex else {
            return nil
        }
        
        return ordererdViewcontrollers[prevIndex]
        
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let vcIndex = ordererdViewcontrollers.index(of: viewController) else {
            return nil
        }
        
        let nextIndex = vcIndex + 1
        
        guard ordererdViewcontrollers.count != nextIndex else {
            return nil
        }
        
        guard ordererdViewcontrollers.count > nextIndex else {
            return nil
        }
        
        return ordererdViewcontrollers[nextIndex]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        let pageVC = pageViewController.viewControllers![0]
        pageCtrl.currentPage = ordererdViewcontrollers.index(of: pageVC)!
    }
}
