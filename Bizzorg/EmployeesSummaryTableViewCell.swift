//
//  EmployeesSummaryTableViewCell.swift
//  Bizzorg
//
//  Created by Jordan Field on 16/09/2016.
//  Copyright © 2016 Jordan Field. All rights reserved.
//

import UIKit

/**
 View controller responsible for the carousel of profile pictures seen in the
 group detail table view and to-do and schedule item table views.
 
 UI links
 ========
 employeesCollectionView
 
 Properties
 ==========
 employees - a list of Employee objects that will make up each of the individual
 cells.
 */
class EmployeesSummaryTableViewCell: UITableViewCell,
  UICollectionViewDelegate,
  UICollectionViewDataSource {
  
  var employees: [Employee] = []
  
  /*
   This cell actually conisits of a collection view cells inside a table view
   cell. Collection views are very very similar to table views in that they
   use the same kind of data source and delegate functions (numberOfSections,
   cellForItemAt indexPath instead of cellForRowAt etc). This setup allows for
   the scrollable nature of the cell instead of being fixed, which helps with UI.
  */
  @IBOutlet weak var employeesCollectionView: UICollectionView!
  override func awakeFromNib() {
    super.awakeFromNib()
    //When the cell initialises, set the data source and delegate of the 
    //collection view to this class, so the collection view functions will be 
    //called on this class.
    employeesCollectionView.delegate = self
    employeesCollectionView.dataSource = self
  }
  
  //The collection view only has one section, which contains all the items.
  func numberOfSections(in collectionView: UICollectionView) -> Int {
    return 1
  }
  
  //The number of collection view cells will correspond to the number of 
  //items in the employees list.
  func collectionView(_ collectionView: UICollectionView,
                      numberOfItemsInSection section: Int) -> Int {
    return employees.count
  }
  
  func collectionView(_ collectionView: UICollectionView,
                  cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    //Retrieve a member collection view cell for the table view.
    let cell =
      collectionView.dequeueReusableCell(withReuseIdentifier: "member-cell",
                                  for: indexPath) as! MemberCollectionViewCell
    //Assign the employee for this cell into the collection view cell class, so
    //that the details can be displayed in the cell.
    cell.employee = employees[indexPath.row]
    return cell
  }
  
}
