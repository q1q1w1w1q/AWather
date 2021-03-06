//
//  MainViewController.swift
//  Weather
//
//  Created by Allen Wang on 2017/6/24.
//  Copyright © 2017年 Allen Wang. All rights reserved.
//

import UIKit
import AVFoundation
import Kingfisher
import GooglePlacePicker
import PKHUD

class MainViewController: UIViewController {

    @IBOutlet weak var dailyCollectionView: UICollectionView!
    @IBOutlet weak var hourlyCollectionView: UICollectionView!
    @IBOutlet weak var flow: UICollectionViewFlowLayout!
    
    @IBOutlet weak var centralBtn: UIButton!
    @IBOutlet weak var ivWeather: UIImageView!
    @IBOutlet weak var lbDate: UILabel!
    @IBOutlet weak var lbCity: UILabel!
    @IBOutlet weak var lbDegree: UILabel!
    
    var viewModel: MainViewModel!
    var dailyDelegate :HierarchyCollectionViewDelegate?
    var hourlyDelegate :HierarchyCollectionViewDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        checkInternet()
        
        viewModel = MainViewModel(handler: self)
        
        viewModel.prepareAudioSession()
        viewModel.askGPS()
        viewModel.getWeatherData()

        setUpCollctionViewCell()
        setUpNavigationBar()        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func userHistory(from btn: UIButton) {
        let history = HistoryViewController()
        history.popoverPresentationController?.sourceView = btn
        history.popoverPresentationController?.sourceRect = btn.bounds
        self.present(history, animated: true, completion: nil)
    }

    func pickPlaceFromMap(from btn: UIButton) {
        let config = GMSPlacePickerConfig(viewport: nil)
        let placePicker = GMSPlacePickerViewController(config: config)
        placePicker.delegate = self
        placePicker.modalPresentationStyle = .popover
        placePicker.popoverPresentationController?.sourceView = btn
        placePicker.popoverPresentationController?.sourceRect = btn.bounds
        self.present(placePicker, animated: true, completion: nil)
    }
    
    func shareToNetwork(from btn: UIButton) {
        HUD.flash(.progress, delay: 1)
        
        if let image = Util.getScreenShot() {
            Util.shareToSocailMedia(from: self, on: btn, with: image)
        } else {
            let title = NSLocalizedString("Oops", comment: "")
            let msg = NSLocalizedString("Unable to share now, please retry later", comment: "")
            Util.popUpDialog(vc: self, on: btn, title: title, message: msg)
        }
    }
    
    private func checkInternet() {
        if !Util.isInternetAvailable() {
            let t = NSLocalizedString("Error", comment: "")
            let m = NSLocalizedString("Please check your internet status and reopen the app", comment: "")
            Util.popUpDialog(vc: self, on: centralBtn, title: t, message: m)
        }
    }
    
    private func setUpCollctionViewCell() {
        let cell = UINib(nibName: "MainColletionViewCell", bundle: nil)

        dailyDelegate = HierarchyCollectionViewDelegate()
        dailyCollectionView.register(cell, forCellWithReuseIdentifier: "mainCell")
        dailyCollectionView.delegate = dailyDelegate
        dailyCollectionView.dataSource = dailyDelegate
    
        hourlyDelegate = HierarchyCollectionViewDelegate()
        hourlyCollectionView.register(cell, forCellWithReuseIdentifier: "mainCell")
        hourlyCollectionView.delegate = hourlyDelegate
        hourlyCollectionView.dataSource = hourlyDelegate
    }
 
    private func setUpNavigationBar() {
        self.title = NSLocalizedString("AWeather", comment: "")
        self.navigationController?.isNavigationBarHidden = false
        
        let location = UIButton.init(type: .custom)
        location.setImage(#imageLiteral(resourceName: "current location"), for: UIControlState.normal)
        location.addTarget(viewModel, action:#selector(MainViewModel.askGPS), for: .touchUpInside)
        location.frame = CGRect.init(x: 0, y: 0, width: 30, height: 30)
        let locationItem = UIBarButtonItem.init(customView: location)
        
        let map = UIButton()
        map.setImage(#imageLiteral(resourceName: "map-1"), for: UIControlState.normal)
        map.addTarget(self, action:#selector(pickPlaceFromMap(from:)), for: .touchUpInside)
        map.frame = CGRect.init(x: 0, y: 0, width: 30, height: 30)
        let mapItem = UIBarButtonItem.init(customView: map)
        
        let share = UIButton()
        share.setImage(#imageLiteral(resourceName: "share"), for: UIControlState.normal)
        share.addTarget(self, action:#selector(shareToNetwork(from:)), for: .touchUpInside)
        share.frame = CGRect.init(x: 0, y: 0, width: 30, height: 30)
        let shareItem = UIBarButtonItem.init(customView: share)

        let rightButtons = [shareItem, mapItem, locationItem]
        self.navigationItem.setRightBarButtonItems(rightButtons, animated: true)
        
        let history = UIButton()
        history.setImage(#imageLiteral(resourceName: "history"), for: UIControlState.normal)
        history.addTarget(self, action:#selector(userHistory(from:)), for: .touchUpInside)
        history.frame = CGRect.init(x: 0, y: 0, width: 30, height: 30)
        let historyItem = UIBarButtonItem.init(customView: history)

        // self.navigationItem.leftBarButtonItem = historyItem
        self.navigationItem.setLeftBarButton(historyItem, animated: true)
    }
}

extension MainViewController : GMSPlacePickerViewControllerDelegate {
    func placePicker(_ viewController: GMSPlacePickerViewController, didPick place: GMSPlace) {
        let c = place.coordinate
        let l = CLLocation(latitude: c.latitude, longitude: c.longitude)
        viewModel.currentLocation = l
        viewModel.getWeatherData()
        
        viewController.dismiss(animated: true, completion: nil)
    }
    
    func placePicker(_ viewController: GMSPlacePickerViewController, didFailWithError error: Error) {
        NSLog("An error occurred while picking a place: \(error)")
    }
    
    func placePickerDidCancel(_ viewController: GMSPlacePickerViewController) {
        NSLog("The place picker was canceled by the user")
        viewController.dismiss(animated: true, completion: nil)
    }
}

extension MainViewController: MainViewModelProtocol{
    func getDailyDataFinished() {
        HUD.flash(.progress, delay: 0.5)

        let todayWeather = viewModel.forecasts[0]
        let url = URL(string: Constant.WEATHER_IMAGE_URL + todayWeather.icon + ".png")

        lbDate.text = Util.tranfer(todayWeather.time!, to: "MMM dd YYYY")
        lbCity.text = viewModel.country! + ", " + viewModel.city!
        lbDegree.text = "\(todayWeather.minDegrees) ~\(todayWeather.maxDegrees)°C"
        ivWeather.kf.setImage(with: url)
        
        dailyDelegate?.weathers = viewModel.forecasts
        dailyDelegate?.city = viewModel.city!
        dailyDelegate?.isDaily = true
        dailyCollectionView.reloadData()
    }
    
    func getHourlyDataFinished() {
        hourlyDelegate?.weathers = viewModel.curWeather
        hourlyDelegate?.city = viewModel.city!
        hourlyDelegate?.isDaily = false
        hourlyCollectionView.reloadData()
    }
}
