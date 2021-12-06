//
//  Page.swift
//  fitstyle
//
//  Created by Joel Goncalves on 11/25/21.
//

import Foundation

struct Page {
    let image: String
    let title: String
    let details: String
}

let tutorialPages = [
    Page(image: "", title: "Welcome! 👋", details: "Thank you for downloading the Fitstyle app!.\nHere is a quick tutorial on how the app works and how to use it."),
    Page(image: "", title: "How does it work? 🤔", details: "Fitstyle is a filter that takes two images, a photo (ideally a full body portrait) and a style image (like a painting), and combines the two to create a unique image. Our filter applies the style’s look to the background of the photo, keeping the person unfiltered.\n\nThis is done in two simple steps... 👉"),
    Page(image: "tutorial_style_selection", title: "Select a style 🎨", details: "Pick from a list of different artworks or upload your own image."),
    Page(image: "tutorial_photo_selection", title: "Choose a photo 📸", details: "From your gallery, choose a photo that you'd like to style."),
    Page(image: "tutorial_style_result", title: "Voilà! 🎉", details: "Share your new masterpiece with the world")
]
