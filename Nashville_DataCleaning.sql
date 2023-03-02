select * from PortfolioProject..NashvilleHousing$;

-- Standardize Date Format (trim time from the data)

	-- select SaleDate, CONVERT(date,SaleDate) from PortfolioProject..NashvilleHousing$;

alter table PortfolioProject..NashvilleHousing$
add SaleDateConverted date;

update PortfolioProject..NashvilleHousing$
set SaleDateConverted = CONVERT(date, [SaleDate]);

	-- select SaleDateConverted, CONVERT(date,SaleDate) from PortfolioProject..NashvilleHousing$;

-- Populate Property Address Data (fill rows having similarity with other obs.)

select * from PortfolioProject..NashvilleHousing$
-- where PropertyAddress is null
order by ParcelID; -- found that first parcel id has property address which can be copied to the consecutive same parcel ids.

select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
from PortfolioProject..NashvilleHousing$ a
join PortfolioProject..NashvilleHousing$ b
on a.ParcelID = b.ParcelID and a.[UniqueID ] != b.[UniqueID ]
where a.PropertyAddress is null;

update a
set PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
from PortfolioProject..NashvilleHousing$ a
join PortfolioProject..NashvilleHousing$ b
on a.ParcelID = b.ParcelID and a.[UniqueID ] != b.[UniqueID ]
where a.PropertyAddress is null;

-- Breaking Address into separate columns (Address, City, State)

select PropertyAddress from PortfolioProject..NashvilleHousing$;

select PropertyAddress, 
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress, 1) - 1),
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress, 1) + 1, LEN(PropertyAddress))
from PortfolioProject..NashvilleHousing$;

alter table PortfolioProject..NashvilleHousing$
add PropertyStreetName varchar(255), PropertyCity varchar(255);

update PortfolioProject..NashvilleHousing$
set PropertyStreetName = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress, 1) - 1),
PropertyCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress, 1) + 1, LEN(PropertyAddress));

select OwnerAddress from PortfolioProject..NashvilleHousing$;

select OwnerAddress, 
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1),
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)
from PortfolioProject..NashvilleHousing$;

alter table PortfolioProject..NashvilleHousing$
add OwnerStreetName varchar(255), OwnerCity varchar(255), OwnerState varchar(255);

update PortfolioProject..NashvilleHousing$
set OwnerStreetName = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
OwnerCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
OwnerState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1);

-- Change "Y" and "N" to "Yes" and "No" repectively in SoldasVacant column

select SoldAsVacant, count(SoldAsVacant)
from PortfolioProject..NashvilleHousing$
group by SoldAsVacant
order by 2;

select SoldAsVacant,
CASE WHEN SoldAsVacant = 'Y' THEN 'YES'
	 WHEN SoldAsVacant = 'N' THEN 'NO'
	 ELSE SoldAsVacant
END
from PortfolioProject..NashvilleHousing$;

update PortfolioProject..NashvilleHousing$
set SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'YES'
						WHEN SoldAsVacant = 'N' THEN 'NO'
						ELSE SoldAsVacant
					END;

-- Remove Duplicates

-- Method 1 (subquery and row_number)

select * from
(select *, ROW_NUMBER() 
OVER (PARTITION BY ParcelID, PropertyAddress, SaleDate, SalePrice, LegalReference ORDER BY UniqueID) as row_no
from PortfolioProject..NashvilleHousing$) x
where x.row_no > 1;

-- Method 2 (CTE and rank)

with RowNoCTE as
(select *, rank() 
OVER (PARTITION BY ParcelID, PropertyAddress, SaleDate, SalePrice, LegalReference ORDER BY UniqueID) as rank_no
from PortfolioProject..NashvilleHousing$)
select * from RowNoCTE a 
where a.rank_no > 1;

-- Delete duplicate rows

with RowNoCTE as
(select *, rank() 
OVER (PARTITION BY ParcelID, PropertyAddress, SaleDate, SalePrice, LegalReference ORDER BY UniqueID) as rank_no
from PortfolioProject..NashvilleHousing$)
delete from RowNoCTE 
where rank_no > 1;

-- Pop out unwanted columns

select Top 10 * from PortfolioProject..NashvilleHousing$;

alter table PortfolioProject..NashvilleHousing$
drop column PropertyAddress, OwnerAddress, TaxDistrict, SaleDate;
