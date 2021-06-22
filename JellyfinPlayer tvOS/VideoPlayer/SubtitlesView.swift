//
/*
 * SwiftFin is subject to the terms of the Mozilla Public
 * License, v2.0. If a copy of the MPL was not distributed with this
 * file, you can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Copyright 2021 Aiden Vigue & Jellyfin Contributors
 */

import SwiftUI

class SubtitlesViewController: UIViewController {
    
    var height : CGFloat = 420

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tabBarItem.title = "Subtitles"
        
    }
    
    
    func prepareSubtitleView(subtitleTracks: [Subtitle], selectedTrack: Int32, delegate: VideoPlayerSettingsDelegate)
    {
        let contentView = UIHostingController(rootView: SubtitleView(selectedTrack: selectedTrack, subtitleTrackArray: subtitleTracks, delegate: delegate))
        self.view.addSubview(contentView.view)
        contentView.view.translatesAutoresizingMaskIntoConstraints = false
        contentView.view.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        contentView.view.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        contentView.view.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        contentView.view.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        
    }
    
    //
    //
    //    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    //        return subtitleTrackArray.count
    //    }
    //
    //    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    //        let cell = UITableViewCell()
    //        let subtitle = subtitleTrackArray[indexPath.row]
    //        cell.textLabel?.text = subtitle.name
    //
    //        let image = UIImage(systemName: "checkmark", withConfiguration: UIImage.SymbolConfiguration(pointSize: (27), weight: .bold))?.withRenderingMode(.alwaysOriginal).withTintColor(.white)
    //        cell.imageView?.image = image
    //
    //        if selectedTrack != subtitle.id {
    //            cell.imageView?.isHidden = true
    //        }
    //        else {
    //            selectedTrackCellRow = indexPath.row
    //        }
    //
    //        return cell
    //    }
    //
    //    func tableView(_ tableView: UITableView, didUpdateFocusIn context: UITableViewFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
    //
    //        if let path = context.nextFocusedIndexPath {
    //            if path.row == selectedTrackCellRow {
    //                let cell : UITableViewCell  = tableView.cellForRow(at: path)!
    //                cell.imageView?.image = cell.imageView?.image?.withTintColor(.black)
    //            }
    //        }
    //
    //        if let path = context.previouslyFocusedIndexPath {
    //            if path.row == selectedTrackCellRow {
    //                let cell : UITableViewCell  = tableView.cellForRow(at: path)!
    //                cell.imageView?.image = cell.imageView?.image?.withTintColor(.white)
    //            }
    //        }
    //
    //    }
    //
    //
    //    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    //        let oldPath = IndexPath(row: selectedTrackCellRow, section: 0)
    //        if let oldCell : UITableViewCell  = tableView.cellForRow(at: oldPath) {
    //            oldCell.imageView?.isHidden = true
    //        }
    //
    //        let cell : UITableViewCell = tableView.cellForRow(at: indexPath)!
    //        cell.imageView?.isHidden = false
    //        cell.imageView?.image = cell.imageView?.image?.withTintColor(.black)
    //
    //        selectedTrack = Int32(subtitleTrackArray[indexPath.row].id)
    //        selectedTrackCellRow = indexPath.row
    ////        infoTabBar?.videoPlayer?.subtitleTrackChanged(newTrackID: selectedTrack)
    //        print("setting new subtitle")
    //        tableView.deselectRow(at: indexPath, animated: false)
    //
    //    }
    //
    //    func numberOfSections(in tableView: UITableView) -> Int {
    //        return 1
    //    }
    //
    //
    
    
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
    
}

struct SubtitleView: View {
    
    @State var selectedTrack : Int32 = -1
    @State var subtitleTrackArray: [Subtitle] = []
    
    weak var delegate: VideoPlayerSettingsDelegate?
    
    
    var body : some View {
        NavigationView {
            VStack() {
                List(subtitleTrackArray, id: \.id) { track in
                    Button(action: {
                        delegate?.selectNew(subtitleTrack: track.id)
                        selectedTrack = track.id
                    }, label: {
                        HStack(spacing: 10){
                            if track.id == selectedTrack {
                                Image(systemName: "checkmark")
                            }
                            else {
                                Image(systemName: "checkmark")
                                    .hidden()
                            }
                            Text(track.name)
                        }
                    })
                    
                }
            }
            .frame(width: 400)
            .frame(maxHeight: 400)
            
        }
    }
    
}
