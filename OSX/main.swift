//
//  main.swift
//  Gureum
//
//  Created by Jeong YunWon on 2018. 9. 26..
//  Copyright © 2018 youknowone.org. All rights reserved.
//

import Cocoa

// _ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)

guard let mainNibName = Bundle.main.infoDictionary?["NSMainNibFile"] as? String else {
  fatalError("Gureum: Info.plist missing NSMainNibFile (String)")
}
guard let nib = NSNib(nibNamed: NSNib.Name(mainNibName), bundle: Bundle.main) else {
  fatalError("Gureum: failed to load main nib '\(mainNibName)'")
}
if nib.instantiate(withOwner: NSApplication.shared, topLevelObjects: nil) == false {
  dlog(true, "!! Gureum fails to load Main Nib File !!")
}

dlog(true, "****   Main bundle \(mainNibName) loaded   ****")
NSApplication.shared.run()
dlog(true, "******* Gureum finalized! *******")
