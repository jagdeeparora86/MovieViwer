//
//  MoviesViewController.swift
//  MovieViewer
//
//  Created by Singh, Jagdeep on 10/11/16.
//  Copyright © 2016 Singh, Jagdeep. All rights reserved.
//

import UIKit
import AFNetworking
import MBProgressHUD


class MoviesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {
    
    @IBOutlet var mainView: UIView!
    @IBOutlet weak var ViewSegment: UISegmentedControl!
    @IBOutlet weak var ErrorView: UIView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var networkErrorView: UIView!
    @IBOutlet weak var movieSearchBar: UISearchBar!
    
    @IBOutlet weak var searchBarView: UIView!
    @IBOutlet weak var collectionSearchBar: UISearchBar!
    var movies : [NSDictionary]?
    var filterMovies: [NSDictionary]!
    var endpoint : String!
    let refreshControl = UIRefreshControl()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        collectionView.delegate = self
        collectionView.dataSource = self
        movieSearchBar.delegate = self
        networkErrorView.isHidden = true
        collectionView.isHidden = true
        setupCollectionView()
        self.refreshControl.addTarget(self, action: #selector(refreshControlAction(refreshControl: )), for: UIControlEvents.valueChanged)
        self.tableView.insertSubview(refreshControl, at: 0)
        makeNetworkCall()
    }
    
    func setupCollectionView(){
        
        collectionView.register(MovieCollectionViewCell.self, forCellWithReuseIdentifier:"MovieCell")
    }
    
    override func didReceiveMemoryWarning() {
        
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let count = filterMovies?.count{
            return count
        }
        else
        {
            return 0
        }
    }
    
    
    @IBAction func switchView(_ sender: AnyObject) {
        if(ViewSegment.selectedSegmentIndex == 0){
            tableView.isHidden = false
            collectionView.isHidden = true
        }
        else{
            tableView.isHidden = true
            collectionView.isHidden = false
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell{
        let cell = tableView.dequeueReusableCell(withIdentifier: "MovieCell", for: indexPath) as! MovieCell
        let movie = filterMovies![indexPath.row]
        let title = movie["title"] as! String
        let overview = movie["overview"] as! String
        cell.overviewLabel.text = overview
        cell.titleLabel.text = title
        cell.overviewLabel.sizeToFit()
        if let posterPath = movie["poster_path"] as? String {
            let posterBaseUrl = "http://image.tmdb.org/t/p/w500"
            let lowResBaseUrl  = "http://image.tmdb.org/t/p/w185_and_h278_bestv2"
            let lowResUrl = URL(string: lowResBaseUrl + posterPath)
            let posterUrl = URL(string: posterBaseUrl + posterPath)
            let smallImageRequest = URLRequest(url: lowResUrl!)
            let largeImageRequest = URLRequest(url: posterUrl!)
            cell.posterView.setImageWith(
                smallImageRequest,
                placeholderImage: nil,
                success: { (smallImageRequest, smallImageResponse, smallImage) -> Void in
                    
                    // smallImageResponse will be nil if the smallImage is already available
                    // in cache (might want to do something smarter in that case).
                    cell.posterView.alpha = 0.0
                    cell.posterView.image = smallImage;
                    print("small image set")
                    UIView.animate(withDuration: 0.3, animations: { () -> Void in
                        
                        cell.posterView.alpha = 0.6
                        
                        }, completion: { (sucess) -> Void in
                            
                            // The AFNetworking ImageView Category only allows one request to be sent at a time
                            // per ImageView. This code must be in the completion block.
                            cell.posterView.setImageWith(
                                largeImageRequest,
                                placeholderImage: smallImage,
                                success: { (largeImageRequest, largeImageResponse, largeImage) -> Void in
                                    print("large image set")
                                    cell.posterView.image = largeImage;
                                    cell.posterView.alpha = 1.0
                                    
                                },
                                failure: { (request, response, error) -> Void in
                                    // do something for the failure condition of the large image request
                                    // possibly setting the ImageView's image to a default image
                            })
                    })
                },
                failure: { (request, response, error) -> Void in
                    // do something for the failure condition
                    // possibly try to get the large image
            })
            
            //            cell.movieImageView.setImageWith(posterUrl! as! URL)
        }
        else {
            // No poster image. Can either set to nil (no image) or a default movie poster image
            // that you include as an asset
            cell.posterView.image = nil
        }
        return cell
    }
    
    
    // This is block is making the network call to get the data from the api.
    // This is used inside the app loaded and when pull to refresh call is made.
    func makeNetworkCall(){
        
        let apiKey = "a07e22bc18f5cb106bfe4cc1f83ad8ed"
        let url = URL(string:"https://api.themoviedb.org/3/movie/\(endpoint!)?api_key=\(apiKey)")
        let request = URLRequest(url: url!)
        let session = URLSession(
            configuration: URLSessionConfiguration.default,
            delegate:nil,
            delegateQueue:OperationQueue.main
        )
        
        MBProgressHUD.showAdded(to: self.view, animated: true)
        let task : URLSessionDataTask = session.dataTask(with: request,completionHandler: { (dataOrNil, response, error) in
            if let data = dataOrNil {
                if let responseDictionary = try! JSONSerialization.jsonObject(with: data, options:[]) as? NSDictionary {
                    MBProgressHUD.hide(for: self.view, animated: true)
                    self.movies = responseDictionary["results"] as? [NSDictionary]
                    self.filterMovies = self.movies
                    self.tableView.reloadData()
                    self.collectionView.reloadData()
                    if(self.refreshControl.isRefreshing){
                        self.refreshControl.endRefreshing()
                    }
                    if(!self.networkErrorView.isHidden){
                        self.networkErrorView.isHidden = true
                    }
                }
            }
            else {
                MBProgressHUD.hide(for: self.view, animated: true)
                self.refreshControl.endRefreshing()
                self.networkErrorView.frame = CGRect(x: 0, y: -25, width: self.networkErrorView.frame.width, height: self.networkErrorView.frame.height)
                self.networkErrorView.isHidden = false
            }
        });
        task.resume()
    }
    
    func refreshControlAction(refreshControl: UIRefreshControl){
        makeNetworkCall()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String){ // called when text changes (including clear)
        if searchText.isEmpty{
            // NO DATA ENTERED
            filterMovies = movies
        }
        else{
            filterMovies = movies?.filter({(dataItem: NSDictionary) -> Bool in
                let title = dataItem["title"] as! String
                if (title.range(of: searchText, options: NSString.CompareOptions.caseInsensitive) != nil){
                    return true
                }
                else
                {
                    return false
                }
                
            })
        }
        collectionView.reloadData()
        tableView.reloadData()
    }
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        var indexpath: IndexPath
        
        if(!tableView.isHidden){
            let cell = sender as! UITableViewCell
            indexpath = tableView.indexPath(for: cell)!
        }
        else {
            indexpath = sender as! IndexPath
        }
        
        let detailViewController = segue.destination as! DetailViewController
        detailViewController.movie = filterMovies![indexpath.row]
    }
    
}


extension MoviesViewController: UICollectionViewDelegate, UICollectionViewDataSource{
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
        
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let count = filterMovies?.count{
            return count
        }
        else
        {
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        print("Inside hello")
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MovieCell", for: indexPath) as! MovieCollectionViewCell
        
        cell.awakeFromNib()
        let movie = filterMovies![indexPath.row]
        
        if let posterPath = movie["poster_path"] as? String {
            let posterBaseUrl = "http://image.tmdb.org/t/p/w500"
            let posterUrl = NSURL(string: posterBaseUrl + posterPath)
            cell.movieImageView.setImageWith(posterUrl! as! URL)
        }
        else {
            // No poster image. Can either set to nil (no image) or a default movie poster image
            // that you include as an asset
            cell.movieImageView.image = nil
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath){
        
        performSegue(withIdentifier: "segueToDetailViewController", sender: indexPath)
        
    }
}

