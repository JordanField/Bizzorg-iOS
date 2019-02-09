//
//  Constants.swift
//  BizzorgServerTest
//
//  This file contains Constants, errors and type-aliases used throughout this app.
//
//  Created by Jordan Field on 17/04/2016.
//  Copyright © 2016 Jordan Field. All rights reserved.
//

import Foundation
import UIKit

//type extensions

//An extension for the UIImage type that allows resizing to an appropriate size
//to send to the server with.
extension UIImage: InitializableFromData {
  func resize(_ size: CGSize) -> UIImage {
    
    //Create a UIImageview to hold the image in.
    let imageview =
      UIImageView(frame: CGRect(origin: CGPoint(x: 0, y: 0), size: size))
    //Set the fill setting to not distort the image, instead to scale the image
    //until it fits the frame.
    imageview.contentMode = UIViewContentMode.scaleAspectFill
    imageview.image = self
    
    //Create a graphics context that will be used to render the resized image.
    UIGraphicsBeginImageContext(size)
    //Render the resized image.
    imageview.layer.render(in: UIGraphicsGetCurrentContext()!)
    
    //Retrieve the newly rendered image.
    let result = UIGraphicsGetImageFromCurrentImageContext()
    
    //Terminate the graphics context.
    UIGraphicsEndImageContext()
    
    //Return the rendered image.
    return result!
  }
}

//An extension to the boolean type that adds a toggle function.
extension Bool {
  mutating func toggle() {
    self = !self
  }
}

//An extension to the Date type that creates a computed variable that always
//shows the current date and time.
extension Date {
  static var now: Date {
    return Date(timeIntervalSinceNow: 0)
  }
}


/**
 An extension to the UIImageViewType.
 
 Functions
 =========
 
 makeCircle: Converts the image view frame into a circle.
 
 updateImage: will correctly update the image in the view
 When called with an image.
 */
extension UIImageView {
  func makeCircle() {
    executeUiChange {
      self.layer.cornerRadius = self.frame.size.width/2
      self.clipsToBounds = true
    }
  }
  
  func updateImage(_ newImage: UIImage?) {
    executeUiChange {
      self.image = newImage
    }
  }
}

/**
 UI Changes must be pushed to the main thread in order to ensure they complete
 correctly, so this small function takes another block of code and pushes it
 to the main thread to be run when possible. Since UI changes do not have to 
 occur immediately, this is an acceptable tradeoff.
 */
func executeUiChange(_ block: @escaping () -> Void) {
  DispatchQueue.main.async(execute: block)
}

//Global constants
let baseUrl = URL(string: "http://jordans-macbook-pro.local:8000")!
let apiUrl = URL(string: "/api/v1/", relativeTo: baseUrl)!
let defaultProfilePicture = UIImage(named: "defaultProfilePicture")!
let globalUrlSession = URLSession(configuration: .default)
let globalUserDefaults = UserDefaults()
let alertIntro = "Something went wrong. Show your administrator this message:"

//type-aliases

/**
 The KeyValuePairs typealias is one of the most important foundations of the
 Bizzorg app. It is used for retrieveing and sending data to the server,
 creating native swift models and converting swift created models into JSON.
 */
typealias KeyValuePairs = [String: Any]

//protocols

//Types with this protocol can be used with the getObjectFromUri() function.
protocol InitializableFromData {
  init?(data: Data)
}

//All swift Bizzorg model representations will have this protocol. This allows
//the responseObjectToDataModels() function to work.
protocol ApiDataModel: InitializableFromData {
  init(data: KeyValuePairs) throws
  var resourceUri: URL {get set}
  var id: Int {get}
}

//Used for picker views to ensure items can be displayed correctly.
protocol Titleizable {
  var title: String {get}
}

//Used within the item creation screens to ensure compatibilty with the picker
//view cells.
protocol ItemPickerTableViewCellDelegate {
  func pickerViewDidSelect(_ pickerViewCell: ItemPickerTableViewCell)
}

//As above.
protocol DatePickerTableViewCellDelegate {
  func datePickerViewDidSelect(_ datePicker: UIDatePicker,
                               cell: DatePickerTableViewCell)
}

//Errors
enum LoginError: Error {
    case userAlreadyLoggedIn(userURI: String)
    case noLoggedInUser
}

enum DataError: Error {
  case dataConversionFailed
}

enum NetworkError: Error {
  case noResponseFromServer
  case serverError(statusCode: Int?)
  case dataNotValidJSON
  case noDataRetrievedFromServer
  case invalidOrMissingCSRFToken
  case badRequest
}

enum EmployeeError: Error {
    case invalidDataInKeyValuePairs
}
