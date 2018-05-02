//
//  RegexConstants.swift
//  EMBClient
//
//  Created by Chen Zerui on 26/1/18.
//  Copyright © 2018 Chen Zerui. All rights reserved.
//

import Foundation

let unreadTableStart = "id=\"tab_table\" name=\"bottomTable\" class=\"tablesorter\">"
let readTableStart = "id=\"tab_table1\" name=\"bottomTable\" class=\"tablesorter\">"
let tableEnd = "</table>"

let dateRegex = try! NSRegularExpression(pattern: "([0-9]+-[A-Z][a-z]{2}-[0-9]+)", options: [])
let authorRegex = try! NSRegularExpression(pattern: "tooltip-data=\"(.+?)\"", options: [])
let importanceRegex = try! NSRegularExpression(pattern: "([ABC])<\\/span>", options: [])
let contentRegex = try! NSRegularExpression(pattern: "<a\\s+href=\"\\/Board\\/content\\/([0-9]*)\\?board=([0-9]+).+?\".+?>(.+?)<\\/a>", options: [])
let fileRegex = try! NSRegularExpression(pattern: "addConfirmedChild\\('attaches','([^']+)','([0-9]+)',false,([0-9]+),([0-9])\\)", options: [])
let iframeRegex = try! NSRegularExpression(pattern: "<iframe[^>]+src=\"([^\"]+)", options: [])

let iframeRemovalRegex = try! NSRegularExpression(pattern: "<iframe.+?<\\/iframe>", options: .dotMatchesLineSeparators)
