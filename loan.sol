// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract StudentLoan {

    struct Loan {
        uint256 amount;
        uint256 interestRate;
        uint256 duration;
        uint256 balance;
        uint256 startTime;
        bool isRepaid;
        bool fundsWithdrawn;
        address borrower;
    }

    // Mapping from borrower address to their loan
    mapping(address => Loan) public loans;

    // Events
    event LoanIssued(address indexed borrower, uint256 amount);
    event PaymentMade(address indexed borrower, uint256 amount);
    event LoanRepaid(address indexed borrower);
    event LoanTermsUpdated(address indexed borrower, uint256 newInterestRate, uint256 newDuration);
    event LoanExtended(address indexed borrower, uint256 additionalDuration);
    event FundsWithdrawn(address indexed borrower, uint256 amount);

    // Issue a new loan
    function issueLoan(address _borrower, uint256 _amount, uint256 _interestRate, uint256 _duration) public {
        require(loans[_borrower].amount == 0, "Loan already exists for this borrower.");

        loans[_borrower] = Loan({
            amount: _amount,
            interestRate: _interestRate,
            duration: _duration,
            balance: _amount,
            startTime: block.timestamp,
            isRepaid: false,
            fundsWithdrawn: false,
            borrower: _borrower
        });

        emit LoanIssued(_borrower, _amount);
    }

    // Extend the duration of the loan
    function extendLoanDuration(uint256 _additionalDuration) public {
        Loan storage loan = loans[msg.sender];
        require(loan.amount > 0, "No loan found for this borrower.");
        require(!loan.isRepaid, "Cannot extend a repaid loan.");

        loan.duration += _additionalDuration;

        emit LoanExtended(msg.sender, _additionalDuration);
    }

    // Calculate the outstanding balance with interest
    function calculateOutstandingBalance(address _borrower) public view returns (uint256) {
        Loan storage loan = loans[_borrower];
        require(loan.amount > 0, "No loan found for this borrower.");

        uint256 elapsedTime = block.timestamp - loan.startTime;
        uint256 interest = (loan.balance * loan.interestRate * elapsedTime) / (365 days * 100);
        return loan.balance + interest;
    }

    // Make a payment towards the loan
    function makePayment(uint256 _amount) public {
        Loan storage loan = loans[msg.sender];
        require(loan.amount > 0, "No loan found for this borrower.");
        require(!loan.isRepaid, "Loan already repaid.");
        require(_amount > 0, "Payment amount must be greater than 0.");
        
        uint256 outstandingBalance = calculateOutstandingBalance(msg.sender);
        require(_amount <= outstandingBalance, "Payment exceeds outstanding balance.");
        
        loan.balance -= _amount;
        
        if (loan.balance == 0) {
            loan.isRepaid = true;
            emit LoanRepaid(msg.sender);
        }
        
        emit PaymentMade(msg.sender, _amount);
    }

    // Get loan details
    function getLoanDetails(address _borrower) public view returns (uint256, uint256, uint256, uint256, bool) {
        Loan storage loan = loans[_borrower];
        require(loan.amount > 0, "No loan found for this borrower.");

        return (loan.amount, loan.interestRate, loan.duration, loan.balance, loan.isRepaid);
    }

    // Update loan terms
    function updateLoanTerms(uint256 _newInterestRate, uint256 _newDuration) public {
        Loan storage loan = loans[msg.sender];
        require(loan.amount > 0, "No loan found for this borrower.");
        require(!loan.isRepaid, "Cannot update terms of a repaid loan.");

        loan.interestRate = _newInterestRate;
        loan.duration = _newDuration;

        emit LoanTermsUpdated(msg.sender, _newInterestRate, _newDuration);
    }

    // Withdraw funds for the loan
    function withdrawFunds() public {
        Loan storage loan = loans[msg.sender];
        require(loan.amount > 0, "No loan found for this borrower.");
        require(!loan.fundsWithdrawn, "Funds already withdrawn.");
        require(!loan.isRepaid, "Cannot withdraw from a repaid loan.");
        require(address(this).balance >= loan.amount, "Contract has insufficient funds.");

        loan.fundsWithdrawn = true;
        payable(msg.sender).transfer(loan.amount);

        emit FundsWithdrawn(msg.sender, loan.amount);
    }

    // Fallback function to receive ether
    receive() external payable {}
}
