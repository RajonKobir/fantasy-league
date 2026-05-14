import dayjs from 'dayjs'
import relativeTime from 'dayjs/plugin/relativeTime'

dayjs.extend(relativeTime)

export function useDate() {
  /**
   * Format a date to a human-readable string
   * Example: "Feb 19, 2026 2:58 PM"
   */
  const formatDate = (date) => {
    if (!date) return ''
    return dayjs(date).format('MMM DD, YYYY h:mm A')
  }

  /**
   * Format a date to short format
   * Example: "Feb 19, 2026"
   */
  const formatDateShort = (date) => {
    if (!date) return ''
    return dayjs(date).format('MMM DD, YYYY')
  }

  /**
   * Format a date to time only
   * Example: "2:58 PM"
   */
  const formatTime = (date) => {
    if (!date) return ''
    return dayjs(date).format('h:mm A')
  }

  /**
   * Format a date to relative time
   * Example: "2 hours ago"
   */
  const formatRelative = (date) => {
    if (!date) return ''
    return dayjs(date).fromNow()
  }

  /**
   * Format a date to ISO format for input fields
   * Example: "2026-02-19T14:58"
   */
  const formatISO = (date) => {
    if (!date) return ''
    return dayjs(date).format('YYYY-MM-DDTHH:mm')
  }

  /**
   * Parse and format a date string to human-readable format
   * Handles both ISO and other common formats
   */
  const parseAndFormat = (date) => {
    if (!date) return ''
    try {
      return formatDate(date)
    } catch (error) {
      console.error('Error formatting date:', error)
      return date
    }
  }

  return {
    formatDate,
    formatDateShort,
    formatTime,
    formatRelative,
    formatISO,
    parseAndFormat,
  }
}
