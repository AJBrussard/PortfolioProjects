--------------------
-- Cleaning Data	|
--------------------

SELECT *
FROM PortfolioProject..NashvilleHousing


-- Standardize Date Format
---------------------------

ALTER TABLE NashvilleHousing    --Unable to set SaleDate column directly, added new column
ADD SaleDateConverted Date

UPDATE PortfolioProject..NashvilleHousing
SET SaleDateConverted =  CONVERT(date,SaleDate)

SELECT SaleDateConverted
FROM PortfolioProject..NashvilleHousing


-- Property Address Data
-------------------------

-- Check for NULL
SELECT *
FROM PortfolioProject..NashvilleHousing
WHERE PropertyAddress is null
ORDER BY ParcelID

-- Select all rows where ParcelID matches but address differs due to duplicate entries
SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress
FROM PortfolioProject..NashvilleHousing a
JOIN PortfolioProject..NashvilleHousing b
	ON a.ParcelID=b.ParcelID
	AND a.[UniqueID ]<>b.[UniqueID ]
WHERE a.PropertyAddress is null

-- Fill NULL addresses
UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress,b.PropertyAddress)
FROM PortfolioProject..NashvilleHousing a
JOIN PortfolioProject..NashvilleHousing b
	ON a.ParcelID=b.ParcelID
	AND a.[UniqueID ]<>b.[UniqueID ]
WHERE a.PropertyAddress is null


-- Need to break out property addresses into Address, City, State
-----------------------------------------------------------
SELECT PropertyAddress
FROM PortfolioProject..NashvilleHousing

-- Split out street and city using SUBSTRING based on comma delimiter
SELECT
TRIM(SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1)) as tempStreetAddress,
TRIM(SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1,LEN(PropertyAddress))) as tempCity
FROM PortfolioProject..NashvilleHousing

-- Add and update new columns with street address and city only
ALTER TABLE PortfolioProject..NashvilleHousing
ADD PropertySplitAddress nvarchar(255),
PropertySplitCity nvarchar(255)

UPDATE PortfolioProject..NashvilleHousing
SET PropertySplitAddress = TRIM(SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1)),
PropertySplitCity = TRIM(SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1,LEN(PropertyAddress)))

SELECT PropertySplitAddress, PropertySplitCity
FROM PortfolioProject..NashvilleHousing


-- Split Owner Addresses using PARSENAME
------------------------------------------
SELECT OwnerAddress
FROM PortfolioProject..NashvilleHousing

SELECT 
PARSENAME(REPLACE(OwnerAddress,',','.'),3),
PARSENAME(REPLACE(OwnerAddress,',','.'),2),
PARSENAME(REPLACE(OwnerAddress,',','.'),1)
FROM PortfolioProject..NashvilleHousing

-- Add new columns for each split value and insert parsed data
ALTER TABLE PortfolioProject..NashvilleHousing
ADD OwnerSplitAddress nvarchar(255),
OwnerSplitCity nvarchar(255),
OwnerSplitState nvarchar(255)

UPDATE PortfolioProject..NashvilleHousing
SET OwnerSplitAddress = TRIM(PARSENAME(REPLACE(OwnerAddress,',','.'),3)),
OwnerSplitCity = TRIM(PARSENAME(REPLACE(OwnerAddress,',','.'),2)),
OwnerSplitState = TRIM(PARSENAME(REPLACE(OwnerAddress,',','.'),1))

SELECT OwnerSplitAddress, OwnerSplitCity,OwnerSplitState
FROM PortfolioProject..NashvilleHousing


-- Change 'Y' or 'N' to 'Yes' or 'No' in SoldAsVacant to improve clarity
-----------------------------------------------------------------------------
SELECT DISTINCT SoldAsVacant, COUNT(*)
FROM NashvilleHousing
GROUP BY SoldAsVacant

UPDATE NashvilleHousing
SET SoldAsVacant = 
	CASE
	WHEN SoldAsVacant = 'Y' THEN 'YES'
	WHEN SoldAsVacant = 'N' THEN 'No'
	ELSE SoldAsVacant
	END

SELECT SoldAsVacant
FROM NashvilleHousing


-- Remove Duplicate Entries
------------------------------

WITH RowNumCTE AS
(
SELECT * ,
	ROW_NUMBER() OVER (
	PARTITION BY	ParcelID,
					PropertyAddress,
					SalePrice,
					SaleDate,
					LegalReference
					ORDER BY UniqueID
					) as row_num
FROM NashvilleHousing
)

DELETE
FROM RowNumCTE
WHERE row_num > 1


-- Delete Unused Columns
---------------------------

SELECT *
FROM NashvilleHousing

ALTER TABLE NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate

ALTER TABLE NashvilleHousing
DROP COLUMN SaleDate