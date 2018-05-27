//
//  ViewController.swift
//  3-RxSwift中Subjects使用
//
//  Created by 韩俊强 on 2017/8/2.
//  Copyright © 2017年 HaRi. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxGesture
class ViewController: UIViewController {

    fileprivate lazy var bag : DisposeBag = DisposeBag()
    
    @IBOutlet var phoneNumTextField: UITextField!
    
    @IBOutlet var passWordTextField: UITextField!
    
    @IBOutlet var Ckickbtn: UIButton!
    
    @IBOutlet var redSlider: UISlider!
    
    @IBOutlet var greenSilder: UISlider!
    
    @IBOutlet var blueSilder: UISlider!
    
    @IBOutlet var redTextField: UITextField!
    
    @IBOutlet var greenTextField: UITextField!
    
    @IBOutlet var blueTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configRXComponent()
    }
}

extension ViewController {
    func configRXComponent() {
        addEndEditing()
        addLoginRX()
        addChangeColor()
    }
    
    func addEndEditing() {
        view.rx.tapGesture()
            .when(.recognized)
            .subscribe(
                onNext:{ [weak self]
                    _ in
                    guard let `self` = self else {
                        return
                    }
                    print("tapped!!!")
                    self.view.endEditing(true)
                }
            ).disposed(by: bag)
    }
    
    func addLoginRX() {
        
        let PhoneNum = phoneNumTextField.rx.text.orEmpty.asObservable()
        
        let Psw = phoneNumTextField.rx.text.orEmpty.asObservable()
        
        let validatePhoneNum:Observable<Bool> = PhoneNum.map { (string:String) -> Bool in
            return string.count > 5 && string.count <= 11
        }
        
        let validatePsw:Observable<Bool> = Psw.map { (string: String) -> Bool in
            return string.count >= 0
        }

        let loginEnable:Observable<Bool> = Observable.combineLatest(validatePhoneNum, validatePsw){ ($0,$1) }.shareReplay(1).map({ (x, y) -> Bool in
            return x && y
        }).shareReplay(1)
        
        loginEnable.subscribe(onNext: { [weak self] (x) in
            guard let `self` = self else{return}
            self.Ckickbtn.isEnabled = x
        }).disposed(by: bag)
        
        let phoneAndCode = Observable.combineLatest(PhoneNum, Psw){ ($0, $1) }.shareReplay(1)

        Ckickbtn.rx.tap.withLatestFrom(phoneAndCode).subscribe(onNext: { (x, y) in
            print(x+y)
        }).disposed(by: bag)

    }
    
    func addChangeColor(){
        
        let TextFieldArray: [UITextField] = [redTextField, greenTextField, blueTextField]
        let SliderArray: [UISlider] = [redSlider, greenSilder, blueSilder]
        
        guard TextFieldArray.count == SliderArray.count else {
            return
        }
        
        //将textField 和 silder的值进行绑定
        var valueMergeArray: [Observable<Float>] = [Observable<Float>]()
        
        
        for i in 0..<TextFieldArray.count {
            
            let textField = TextFieldArray[i]
            let slider = SliderArray[i]
            
            //string -> float
            let textToFloat = textField.rx.text.orEmpty.asControlProperty()
                .filter { (string) -> Bool in
                    //想做textField输入限制
                    return string.count > 4 ? false : true
                }.map { Float($0) ?? 0.0 }
            
            //float -> string
            let sliderToText = slider.rx.value.asObservable().map { (value) -> String in
                //slider 值保留小数点后两位
                return String(format: "%.2f", value)
            }
            
            //值绑定
            textToFloat.bind(to: slider.rx.value).disposed(by: bag)
            sliderToText.bind(to: textField.rx.text).disposed(by: bag)
            
            //将textField 和 slider 值merge 后面用combineLastest 组合
            let valueMerge = Observable.of(textToFloat, slider.rx.value.asObservable())
                .merge()
            valueMergeArray.append(valueMerge)
        }
        
        //组合值变化
        let changeColor:Observable<UIColor> = Observable.combineLatest(valueMergeArray[0], valueMergeArray[1], valueMergeArray[2]){ ($0,$1,$2) }.shareReplay(1).map({ (x, y, z) -> UIColor in
            print("x = \(x)")
            return UIColor.init(red: CGFloat(x), green: CGFloat(y), blue: CGFloat(z), alpha: 1)
        }).shareReplay(1)

        //监听值变化
        changeColor.subscribe(onNext: { [weak self] (color) in
            guard let `strongSelf` = self else {
                return
            }
            strongSelf.view.backgroundColor = color
        }).disposed(by: bag)
    }
}

