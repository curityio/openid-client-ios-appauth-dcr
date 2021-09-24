//
//  ApplicationConfigLoader.swift
//
// Copyright (C) 2021 Curity AB.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//   http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Foundation

struct ApplicationConfigLoader {

    static func load() -> ApplicationConfig {

        do {
            
            let configFilePath = Bundle.main.path(forResource: "config", ofType: "json")
            let jsonText = try String(contentsOfFile: configFilePath!)
            let jsonData = jsonText.data(using: .utf8)!
            let decoder = JSONDecoder()

            let data =  try decoder.decode(ApplicationConfig.self, from: jsonData)
            Logger.info(data: data.issuer)
            return data

        } catch {
            
            // TODO: deal with startup errors more correctly
            Logger.info(data: "Load configuration error: \(error)")
            let config = ApplicationConfig()
            return config
        }
    }
}
