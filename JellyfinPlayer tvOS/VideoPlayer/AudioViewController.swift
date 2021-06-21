//
 /* 
  * SwiftFin is subject to the terms of the Mozilla Public
  * License, v2.0. If a copy of the MPL was not distributed with this
  * file, you can obtain one at https://mozilla.org/MPL/2.0/.
  *
  * Copyright 2021 Aiden Vigue & Jellyfin Contributors
  */

import UIKit

class AudioViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    var infoTabBar : InfoTabBarViewController? = nil
    
    var audioTrackArray: [AudioTrack] = []
    
    var selectedTrack : Int32 = -1
    var selectedTrackCellRow : Int = -1
    
    @IBOutlet weak var tableView: UITableView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        tableView.delegate = self
        tableView.dataSource = self
    }

    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return audioTrackArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        let track = audioTrackArray[indexPath.row]
        cell.textLabel?.text = track.name
        
        let image = UIImage(systemName: "checkmark", withConfiguration: UIImage.SymbolConfiguration(pointSize: (27), weight: .bold))?.withRenderingMode(.alwaysOriginal).withTintColor(.white)
        cell.imageView?.image = image
        
        if selectedTrack != track.id {
            cell.imageView?.isHidden = true
        }
        else {
            selectedTrackCellRow = indexPath.row
        }

        return cell
    }
    
    func tableView(_ tableView: UITableView, didUpdateFocusIn context: UITableViewFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        
        if let path = context.nextFocusedIndexPath {
            if path.row == selectedTrackCellRow {
                let cell : UITableViewCell  = tableView.cellForRow(at: path)!
                cell.imageView?.image = cell.imageView?.image?.withTintColor(.black)
            }
        }
        
        if let path = context.previouslyFocusedIndexPath {
            if path.row == selectedTrackCellRow {
                let cell : UITableViewCell  = tableView.cellForRow(at: path)!
                cell.imageView?.image = cell.imageView?.image?.withTintColor(.white)
            }
        }
    
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let oldPath = IndexPath(row: selectedTrackCellRow, section: 0)
        if let oldCell : UITableViewCell  = tableView.cellForRow(at: oldPath) {
            oldCell.imageView?.isHidden = true
        }
        
        let cell : UITableViewCell = tableView.cellForRow(at: indexPath)!
        cell.imageView?.isHidden = false
        cell.imageView?.image = cell.imageView?.image?.withTintColor(.black)
        
        selectedTrack = Int32(audioTrackArray[indexPath.row].id)
        selectedTrackCellRow = indexPath.row
        infoTabBar?.videoPlayer?.audioTrackChanged(newTrackID: selectedTrack)
        tableView.deselectRow(at: indexPath, animated: false)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    

    /*
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

        // Configure the cell...

        return cell
    }
    */

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
