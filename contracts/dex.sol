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
      uint filled;
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
        orders.push(Order(nextOrderId, msg.sender, side, ticker, amount, price, 0));

        if(orders.length > 1) {
            //bubble sort - will will traverse from the tail of the array to the 0th index
            //set the markers for the last index and the penultimate index and the 'buffer' for the swap operation.
            uint rearIdx = orders.length-1;
            uint frontIdx = rearIdx-1;
            Order memory buffer;

            if(side == Side.BUY) { //largest "most interesting" Buy order is closest to 0th position, "the front" (descending order)
                while(frontIdx > 0) {
                    //condition for swapping
                    if(orders[frontIdx].price > orders[rearIdx].price) { break; }
                    //swap
                    buffer = orders[frontIdx];
                    orders[frontIdx] = orders[rearIdx];
                    orders[rearIdx] =  buffer;
                    //shift left
                    frontIdx--;
                    rearIdx--;
                }
            }else if(side == Side.SELL) { //Smallest "most interesting" sell order is at the 0th position, "the front" (ascending order)
                while(frontIdx > 0) {
                    //condition for swapping
                    if(orders[frontIdx].price < orders[rearIdx].price) { break; }
                    //swap
                    buffer = orders[frontIdx];
                    orders[frontIdx] = orders[rearIdx];
                    orders[rearIdx] =  buffer;
                    //shift left
                    frontIdx--;
                    rearIdx--;
                }
            }
        }

        nextOrderId++;
    }

    function createMarketOrder(Side side, bytes32 ticker, uint amount) public returns(uint totalFilled){

        uint orderBookSide;
        if(side == Side.BUY){
            orderBookSide = uint(Side.SELL);
        }
        else{
            require(balances[msg.sender][ticker] >= amount, "Insuffient balance");
            orderBookSide = uint(Side.BUY);
        }
        Order[] storage orders = orderBook[ticker][orderBookSide];

        totalFilled = 0;

        //Let's fill the order the best that we can.  We will allow partial filling of the order

        for (uint256 i = 0; i < orders.length && totalFilled < amount; i++) {
            uint leftToFill = amount.sub(totalFilled);
            uint availableToFill = orders[i].amount.sub(orders[i].filled);
            uint filled = 0;
            if(availableToFill > leftToFill){
                filled = leftToFill; //Fill the entire market order
            }
            else{
                filled = availableToFill; //Fill as much as is available in order[i]
            }

            totalFilled = totalFilled.add(filled);
            orders[i].filled = orders[i].filled.add(filled);
            uint cost = filled.mul(orders[i].price);

            if(side == Side.BUY){
                //Verify that the buyer has enough ETH to cover the purchase (require)
                require(balances[msg.sender]["ETH"] >= cost);
                //msg.sender is the buyer
                balances[msg.sender][ticker] = balances[msg.sender][ticker].add(filled);
                balances[msg.sender]["ETH"] = balances[msg.sender]["ETH"].sub(cost);

                balances[orders[i].trader][ticker] = balances[orders[i].trader][ticker].sub(filled);
                balances[orders[i].trader]["ETH"] = balances[orders[i].trader]["ETH"].add(cost);
            }
            else if(side == Side.SELL){
                //Msg.sender is the seller
                balances[msg.sender][ticker] = balances[msg.sender][ticker].sub(filled);
                balances[msg.sender]["ETH"] = balances[msg.sender]["ETH"].add(cost);

                balances[orders[i].trader][ticker] = balances[orders[i].trader][ticker].add(filled);
                balances[orders[i].trader]["ETH"] = balances[orders[i].trader]["ETH"].sub(cost);
            }

        }
        //Remove 100% filled orders from the orderbook
        while(orders.length > 0 && orders[0].filled == orders[0].amount){
            for (uint256 i = 0; i < orders.length - 1; i++) {
                orders[i] = orders[i + 1];
            }
            orders.pop();
        }

        return totalFilled;
    }
}
