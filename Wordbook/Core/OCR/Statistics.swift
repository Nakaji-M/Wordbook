//
//  Statistics.swift
//  Wordbook
//
//  Created by Masanori on 2024/08/18.
//

import Foundation

class Statistics{
    
    public let PI: Double = 3.141592653589793238462643383279

    public func kernelDensityEstimation(_ array:[Double], _ h:Double)->[Double]{
        var kernel_density_estimation = Array<Double>(repeating: 0, count: array.count)
        for i in 0 ..< array.count {
            for j in 0 ..< array.count {
                kernel_density_estimation[i] += normpdf(array[i], mu: array[j], s: h)
            }
        }
        return kernel_density_estimation
    }
    
    public func sum(_ array:[Double])->Double{
        return array.reduce(0,+)
    }
    
    public func average(_ array:[Double])->Double{
        if array.count==0{
            return 0
        }
        return self.sum(array) / Double(array.count)
    }
    
    public func variance(_ array:[Double])->Double{
        let left=self.average(array.map{pow($0, 2.0)})
        let right=pow(self.average(array), 2.0)
        let count=array.count
        if count==1{
            return 0
        }
        return (left-right)*Double(count/(count-1))
    }
    
    public func normpdf(_ x: Double, mu: Double, s: Double) -> Double {
      return normpdf(x) * s + mu
    }
    
    private func normpdf(_ x: Double) -> Double {
      return 1 / sqrt(2.0 * PI) * exp(-x*x/2.0)
    }
}
