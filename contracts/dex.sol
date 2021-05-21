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

    function createMarketOrder(Side side, bytes32 ticker, uint amount) tokenExists(ticker) public returns (uint totalFilled) {

        if(side == Side.SELL) {
            require(balances[msg.sender][ticker] >= amount, "Insufficient Balance");
        }

        //Selecting the orderbook for the other "side" of this market order.
        //(Ex: If it is a buy order you want to work against the sell orderbook, and vise versa)
        uint orderBookSide;
        if(side == Side.BUY) {
            orderBookSide = uint(Side.SELL);
        } else if (side == Side.SELL) {
            orderBookSide = uint(Side.BUY);
        }
        Order[] storage orders = orderBook[ticker][orderBookSide];

        //Let's fill the order the best that we can.  We will allow partial filling of the order

        totalFilled = 0;

        for(uint i=0; i < orders.length && totalFilled < amount; i++) {
            if (amount > orders[i].amount) { //complete order filling
                orders[i].filled = orders[i].amount;
                orders[i].amount = 0;
                totalFilled = totalFilled.add(orders[i].filled);
            } else if(amount < orders[i].amount) { //partial order filling
                orders[i].amount = orders[i].amount.sub(amount);
                orders[i].filled = amount;
                totalFilled = totalFilled.add(amount);
            }

            //Dispatch the money transfers according to the type of order "side" we are executing.

            if(Side.BUY == side) {
                //make sure that that coin is available on the exchange (in exchange wallet): addressed with function modifier
                //make sure you have enough money to buy the "filled" amount.
                require(balances[msg.sender][bytes32("ETH")] >= orders[i].filled.mul(orders[i].price));
                //as the buyer (buys something, spends money)
                balances[msg.sender][ticker] = balances[msg.sender][ticker].add(orders[i].filled);
                balances[msg.sender][bytes32("ETH")] = balances[msg.sender][bytes32("ETH")].sub(orders[i].filled.mul(orders[i].price));

                //as the seller (trader)
                balances[orders[i].trader][ticker] = balances[orders[i].trader][ticker].sub(orders[i].filled);
                balances[orders[i].trader][bytes32("ETH")] = balances[orders[i].trader][bytes32("ETH")].sub(orders[i].filled.mul(orders[i].price));

                //IERC20(transferFrom)(address(this), orders[i].trader, orders[i].filled.mul(orders[i].price));

            }else if(Side.SELL == side) {
                //as the seller (sells something, gets money)
                balances[msg.sender][ticker] = balances[msg.sender][ticker].sub(orders[i].filled);
                balances[msg.sender][bytes32("ETH")] = balances[msg.sender][ticker].add(orders[i].filled.mul(orders[i].price));
                //as the buyer (buys something, spends money)
                balances[orders[i].trader][ticker] = balances[orders[i].trader][ticker].add(orders[i].filled);
                balances[orders[i].trader][bytes32("ETH")] = balances[orders[i].trader][bytes32("ETH")].sub(orders[i].filled.mul(orders[i].price));

                //IERC20(tokenMapping[ticker].tokenAddress).transfer(orders[i].trader, orders[i].filled);
            }
        }

        //loop through and clean up what has been filled.
        while(orders.length > 0 && orders[0].amount == 0) {
            for(uint i = 0; i < orders.length - 1; i++) {
                orders[i] = orders[i+1];
            }
            orders.pop;
        }

        return totalFilled;
    }
}
