// Copyright 2019, The Jelly Bean World Authors. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License"); you may not
// use this file except in compliance with the License. You may obtain a copy of
// the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
// WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
// License for the specific language governing permissions and limitations under
// the License.

/// Transition of an agent during a single simulation step.
public struct AgentTransition {
  /// State of the agent before the simulation step was performed.
  public let previousState: AgentState

  /// State of the agent after the simulation  step was performed.
  public let currentState: AgentState

  @inlinable
  public init(previousState: AgentState, currentState: AgentState) {
    self.previousState = previousState
    self.currentState = currentState
  }
}

///  Reward function that scores agent transitions.
public enum Reward: Equatable {
  case action(value: Float)
  case collect(item: Item, value: Float)
  indirect case combined(Reward, Reward)

  /// Adds two reward functions. The resulting reward will be equal to the sum of the rewards
  /// computed by the two functions.
  @inlinable
  public static func +(lhs: Reward, rhs: Reward) -> Reward {
    .combined(lhs, rhs)
  }

  /// Returns a reward value for the provided transition.
  ///
  /// - Parameter transition: Agent transition for which to compute a reward.
  /// - Returns: Reward value for the provided transition.
  @inlinable
  public func callAsFunction(for transition: AgentTransition) -> Float {
    switch self {
      case let .action(value):
        return value
      case let .collect(item, value):
        let currentItemCount = transition.currentState.items[item] ?? 0
        let previousItemCount = transition.previousState.items[item] ?? 0
        return Float(currentItemCount - previousItemCount) * value
      case let .combined(reward1, reward2):
        return reward1(for: transition) + reward2(for: transition)
    }
  }
}

extension Reward: CustomStringConvertible {
  public var description: String {
    switch self {
    case let .action(value):
      return "Action[\(String(format: "%.2f", value))]"
    case let .collect(item, value):
      return "Collect[\(item.description), \(String(format: "%.2f", value))]"
    case let .combined(reward1, reward2):
      return "\(reward1.description) ∧ \(reward2.description)"
    }
  }
}

/// Reward function schedule which specifies which reward function is used at each time step.
/// This is useful for representing never-ending learning settings that require adaptation.
public protocol RewardSchedule {
  /// Returns the reward function to use for the specified time step.
  func reward(forStep step: UInt64) -> Reward
}

/// Fixed reward function schedule that uses the same reward function for all time steps.
public struct FixedReward: RewardSchedule {
  public let reward: Reward

  public init(_ reward: Reward) {
    self.reward = reward
  }

  public func reward(forStep step: UInt64) -> Reward {
    reward
  }
}
