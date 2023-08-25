/* 

	Cleaning Data in SQL Queries

*/
--------------------------------------------------------------------------------------------------------------------------------------------------
SELECT * FROM PortfolioProject..NashvilleHousing

-- Standardize the SaleDate format
SELECT SaleDate, CONVERT(Date, SaleDate)
FROM PortfolioProject..NashvilleHousing

ALTER TABLE NashvilleHousing						 -- Add new column name SaleDateConverted as Date format
ADD SaleDateConverted Date;

UPDATE PortfolioProject..NashvilleHousing			 -- Populate the new column from SaleDate
Set SaleDateConverted = SaleDate

--------------------------------------------------------------------------------------------------------------------------------------------------
-- Populate Property Adress Data
SELECT * 
FROM PortfolioProject..NashvilleHousing				 
WHERE PropertyAddress IS NULL
ORDER BY ParcelID

/*
Property address in some rows are NULL so we want to populate that adress.
Some ParcelID in some rows are same, so we can check if one of the same ParcelId has address and other not, in that case we can copy the adress to NULL
*/
SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress,b.PropertyAddress)  
FROM PortfolioProject..NashvilleHousing a
JOIN PortfolioProject..NashvilleHousing b
	ON a.ParcelID = b.ParcelID AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL

-- Join the table to itself, update first table, set property to second table property, ON ParcelID are same AND UniqueID are different
UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress,b.PropertyAddress)
FROM PortfolioProject..NashvilleHousing a
JOIN PortfolioProject..NashvilleHousing b
	ON a.ParcelID = b.ParcelID AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL

--------------------------------------------------------------------------------------------------------------------------------------------------
-- Seperate property address into individual adress (Address, City, State) with SUBSTRING
SELECT PropertyAddress 
FROM PortfolioProject..NashvilleHousing

SELECT 
SUBSTRING (PropertyAddress, 1, (CHARINDEX(',' , PropertyAddress) - 1)) AS Address,				  -- SELECT from first letter to ',' position - 1 
SUBSTRING (PropertyAddress, (CHARINDEX(',' , PropertyAddress) + 1), LEN(PropertyAddress)) AS City -- SELECT from ',' position + 1 to the length of propertyAddress
FROM PortfolioProject..NashvilleHousing


ALTER TABLE PortfolioProject..NashvilleHousing														-- Add new columns (Address, City)				
ADD Address VARCHAR(100);
ALTER TABLE PortfolioProject..NashvilleHousing						
ADD City VARCHAR(100);

UPDATE PortfolioProject..NashvilleHousing															-- Populate new columns from propertyAddress address and city
Set PropertySplitAddress = SUBSTRING (PropertyAddress, 1, (CHARINDEX(',' , PropertyAddress) - 1))
UPDATE PortfolioProject..NashvilleHousing			 
Set PropertySplitCity = SUBSTRING (PropertyAddress, (CHARINDEX(',' , PropertyAddress) + 1), LEN(PropertyAddress))

--------------------------------------------------------------------------------------------------------------------------------------------------
-- Seperate owner address into individual adress (Address, City, State) with PARSE NAME
SELECT OwnerAddress 
FROM PortfolioProject..NashvilleHousing	

SELECT 
PARSENAME (REPLACE(OwnerAddress, ',', '.'), 3),      -- PARSENAME looks for '.' so ve replace ',' with '.'
PARSENAME (REPLACE(OwnerAddress, ',', '.'), 2),		 -- 1 means take the last word after last '.'
PARSENAME (REPLACE(OwnerAddress, ',', '.'), 1)		 -- 2 is take the second last word and so on
FROM PortfolioProject..NashvilleHousing				 -- so PARSENAME works backvards


ALTER TABLE PortfolioProject..NashvilleHousing																		
ADD OwnerSplitAddress VARCHAR(100);
ALTER TABLE PortfolioProject..NashvilleHousing						
ADD OwnerSplitCity VARCHAR(100);
ALTER TABLE PortfolioProject..NashvilleHousing						
ADD OwnerSplitState VARCHAR(100);

UPDATE PortfolioProject..NashvilleHousing															
Set OwnerSplitAddress = PARSENAME (REPLACE(OwnerAddress, ',', '.'), 3)
UPDATE PortfolioProject..NashvilleHousing															
Set OwnerSplitCity = PARSENAME (REPLACE(OwnerAddress, ',', '.'), 2)
UPDATE PortfolioProject..NashvilleHousing															
Set OwnerSplitState = PARSENAME (REPLACE(OwnerAddress, ',', '.'), 1)

EXEC sp_rename 'PortfolioProject..NashvilleHousing.Address', 'PropertySplitAddress', 'COLUMN'; -- Change column name from Address to PropertySplitAddress
EXEC sp_rename 'PortfolioProject..NashvilleHousing.City', 'PropertySplitCity', 'COLUMN';


--------------------------------------------------------------------------------------------------------------------------------------------------
-- 'SoldAsVacant' column, Change Y and N to Yes and No
SELECT DISTINCT (SoldAsVacant), COUNT(SoldAsVacant)
FROM PortfolioProject..NashvilleHousing	
GROUP BY SoldAsVacant
ORDER BY 2
 
Select *
FROM PortfolioProject..NashvilleHousing	
WHERE SoldAsVacant = 'N' OR SoldAsVacant = 'Y'

-- Solution 1 - WHERE
UPDATE PortfolioProject..NashvilleHousing	
SET SoldAsVacant = 'Yes' WHERE SoldAsVacant = 'Y';
UPDATE PortfolioProject..NashvilleHousing	
SET SoldAsVacant = 'No' WHERE SoldAsVacant = 'N';

-- Solution 2 - CASE
UPDATE PortfolioProject..NashvilleHousing	
SET SoldAsVacant = CASE 
	WHEN SoldAsVacant = 'Y' THEN 'YES'
	WHEN SoldAsVacant = 'N' THEN 'NO'
	ELSE SoldAsVacant
	END

--------------------------------------------------------------------------------------------------------------------------------------------------
-- Remove Duplicates with CTE
WITH RowNumCTE AS (
SELECT *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelId,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
					UniqueID
					) row_num

FROM PortfolioProject..NashvilleHousing	
)

SELECT *   -- use DELETE here to delete duplicates
FROM RowNumCTE
WHERE row_num > 1
ORDER BY PropertyAddress

--------------------------------------------------------------------------------------------------------------------------------------------------
-- Delete unused columns
-- Usually Deleting raw data is not recomended 

SELECT *
FROM PortfolioProject..NashvilleHousing	

ALTER TABLE PortfolioProject..NashvilleHousing	
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress

ALTER TABLE PortfolioProject..NashvilleHousing	
DROP COLUMN SaleDate