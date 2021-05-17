/*
  SPDX-License-Identifier: Apache-2.0

  Copyright 2021 The 6th Column Project

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/
pragma solidity 0.8.0;
pragma experimental ABIEncoderV2;

import "./Wallet.sol";

contract Dex is Wallet {

    using SafeMath for uint256;

    enum Side { BUY, SELL }

    struct Order {
      uint id;
      address trader;
      Side side;
      bytes32 ticker;
      uint amount;
      uint price;
    }

    uint public nextOrderId = 0;

    //TICKER to TYPE to ORDERS
    //"ETH"     BUY
    mapping(bytes32 => mapping(uint => Order[])) public orderBook;

    function getOrderBook(bytes32 ticker, Side side) view public returns(Order[] memory) {
        return orderBook[ticker][uint(side)];
    }

    function createLimitOrder(Side side, bytes32 ticker, uint amount, uint price ) public {
        if(side == Side.BUY) {
            require(balances[msg.sender][bytes32("ETH")] >= amount.mul(price), "Insufficent ETH");

        }
        else if(side == Side.SELL) {
            require(balances[msg.sender][ticker] >= amount);

        }

        Order[] storage orders = orderBook[ticker][uint(side)];
        orders.push(Order(nextOrderId, msg.sender, side, ticker, amount, price));

        if(orders.length > 1) {
            //bubble sort - will will traverse from the tail of the array to the 0th index
            //set the markers for the last index and the penultimate index and the tmp 'buffer' for the swap operation.
            uint rearIdx = orders.length-1;
            uint frontIdx = rearIdx-1;
            Order memory tmp;

            if(side == Side.BUY) { //largest "most interesting" Buy order is closest to 0th position, "the front" (descending order)
                for(uint i = uint(orders.length); i == 1 ; i--) {
                    //condition for swapping
                    if(orders[rearIdx].price >orders[frontIdx].price) {
                        tmp = orders[frontIdx];
                        orders[frontIdx] = orders[rearIdx];
                        orders[rearIdx] =  tmp;
                    }
                    frontIdx--;
                    rearIdx--;
                }
            }else if(side == Side.SELL) { //Smallest "most interesting" sell order is at the 0th position, "the front" (ascending order)
                for(uint i = uint(orders.length); i == 1 ; i--) {
                    //condition for swapping
                    if(orders[rearIdx].price < orders[frontIdx].price) {
                        tmp = orders[frontIdx];
                        orders[frontIdx] = orders[rearIdx];
                        orders[rearIdx] =  tmp;
                    }
                    frontIdx--;
                    rearIdx--;
                }
            }
        }

        nextOrderId++;
    }
    //
    //function createMarketOrder() {
    //
    //}
}
